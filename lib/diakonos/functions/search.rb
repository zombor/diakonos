module Diakonos
  module Functions

    # Searches for matches of a regular expression in the current buffer.
    # @param [String] dir_str
    #   The direction to search; 'down' (default) or 'up'.
    # @param [Boolean] case_sensitive
    #   Whether or not the search should be case_sensitive.  Default is insensitive.
    # @param [String] regexp_source_
    #   The regular expression to search for.
    # @param [String] replacement
    #   If provided, do a find and replace, and replace matches with replacement.
    # @see #find_exact
    # @see #find_again
    def find( dir_str = "down", case_sensitive = CASE_INSENSITIVE, regexp_source_ = nil, replacement = nil )
      direction = direction_of( dir_str )

      if regexp_source_
        regexp_source = regexp_source_
      else
        buffer_current.search_area = nil
        m = buffer_current.selection_mark
        if m
          if m.start_row != m.end_row
            buffer_current.search_area = buffer_current.selection_mark
            buffer_current.remove_selection
          else
            selected_text = buffer_current.copy_selection[ 0 ]
          end
        end
        starting_row, starting_col = buffer_current.last_row, buffer_current.last_col

        regexp_source = get_user_input(
          "Search regexp: ",
          history: @rlh_search,
          initial_text: selected_text || ""
        ) { |input|
          if input.length > 1
            find_ direction, case_sensitive, input, nil, starting_row, starting_col, QUIET
          else
            buffer_current.remove_selection Buffer::DONT_DISPLAY
            buffer_current.clear_matches Buffer::DO_DISPLAY
          end
        }
      end

      if regexp_source
        num_replacements = find_( direction, case_sensitive, regexp_source, replacement, starting_row, starting_col, NOISY )
        show_number_of_matches_found( replacement ? num_replacements : nil )
      elsif starting_row && starting_col
        buffer_current.clear_matches
        if @settings[ 'find.return_on_abort' ]
          buffer_current.cursor_to starting_row, starting_col, Buffer::DO_DISPLAY
        end
      end
    end

    # Searches for matches of the latest clipboard item in the current buffer.
    # Note that the clipboard item is interpreted as a regular expression.
    # Only the last line of multi-line clipboard items is used.
    # @param [String] dir_str
    #   The direction to search; 'down' (default) or 'up'.
    # @param [Boolean] case_sensitive
    #   Whether or not the search should be case_sensitive.  Default is insensitive.
    # @see #find
    def find_clip( dir_str = "down", case_sensitive = CASE_INSENSITIVE )
      find dir_str, case_sensitive, @clipboard.clip[-1]
    end

    # Search again for the most recently sought search term.
    # @param [String] dir_str
    #   The direction to search; 'up' or 'down'.
    # @see #find
    # @see #find_exact
    def find_again( dir_str = nil )
      if dir_str
        direction = direction_of( dir_str )
        buffer_current.find_again( @last_search_regexps, direction )
      else
        buffer_current.find_again( @last_search_regexps )
      end
      show_number_of_matches_found
    end

    # Search for an exact string (not a regular expression).
    # @param [String] dir_str
    #   The direction to search; 'down' (default) or 'up'.
    # @param [String] search_term_
    #   The thing to search for.
    # @see #find
    # @see #find_again
    def find_exact( dir_str = "down", search_term_ = nil )
      buffer_current.search_area = nil
      if search_term_.nil?
        if buffer_current.changing_selection
          selected_text = buffer_current.copy_selection[ 0 ]
        end
        search_term = get_user_input(
          "Search for: ",
          history: @rlh_search,
          initial_text: selected_text || ""
        )
      else
        search_term = search_term_
      end
      if search_term
        direction = direction_of( dir_str )
        regexp = [ Regexp.new( Regexp.escape( search_term ) ) ]
        buffer_current.find( regexp, :direction => direction )
        @last_search_regexps = regexp
      end
    end

    # Moves the cursor to the pair match of the current character, if any.
    def go_to_pair_match
      buffer_current.go_to_pair_match
    end

    # Wrapper method for calling #find for search and replace.
    # @see #find
    def search_and_replace( case_sensitive = CASE_INSENSITIVE )
      find( "down", case_sensitive, nil, ASK_REPLACEMENT )
    end
    alias_method :find_and_replace, :search_and_replace

    # Immediately moves the cursor to the next match of a regular expression.
    # The user is not prompted for any value.
    # @param [String] regexp_source
    #   The regular expression to search for.
    # @param [String] dir_str
    #   The direction to search; 'down' (default) or 'up'.
    def seek( regexp_source, dir_str = "down" )
      if regexp_source
        direction = direction_of( dir_str )
        regexp = Regexp.new( regexp_source )
        buffer_current.seek( regexp, direction )
      end
    end

    def show_number_of_matches_found( num_replacements = nil )
      return  if buffer_current.num_matches_found.nil?

      num_found = buffer_current.num_matches_found
      if num_found != 1
        plural = 'es'
      end
      if num_replacements
        set_iline_if_empty "#{num_replacements} out of #{num_found} match#{plural} replaced"
      else
        set_iline_if_empty "#{num_found} match#{plural} found"
      end
    end

  end
end
