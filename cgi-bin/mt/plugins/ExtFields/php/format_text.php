<?php
function format_text( $textformat, $text ) {
    global $mt;
    $ctx =& $mt->context();
    if ( $textformat == 2 ) {
        $formatted_text = html_text_transform( $text );
    } elseif ( $textformat == 3 or $textformat == 4 or $textformat == 5 or $textformat == 6) {
        $lines = preg_split( '/\r\n|\r|\n/', $text, -1, PREG_SPLIT_NO_EMPTY );
        if ( count( $lines ) == 0 ) {
            $formatted_text = '';
        } else {
            $formatted_text = '<table border="1">'."\n";
            if ( $textformat == 4 or $textformat == 6 ) {
                $formatted_text .= '<tr>';
                $values = explode( "\t", array_shift( $lines ) );
                foreach ( $values as $value ) {
                    $formatted_text .= '<th>' . $value . '</th>';
                }
                $formatted_text .= '</tr>'."\n";
            }
            foreach ( $lines as $line ) {
                $formatted_text .= '<tr>';
                $values = explode( "\t", $line );
                if ( $textformat == 5 or $textformat == 6 ) {
                    $formatted_text .= '<th>' . array_shift( $values ) . '</th>';
                }
                foreach ( $values as $value ) {
                    $formatted_text .= '<td>' . $value . '</td>';
                }
                $formatted_text .= '</tr>' . "\n";
            }
            $formatted_text .= '</table>' . "\n";
        }
    } elseif ( $textformat == 7 or $textformat == 8 ) {
        $lines = preg_split( '/\r\n|\r|\n/', $text, -1, PREG_SPLIT_NO_EMPTY );
        if ( count( $lines ) == 0 ) {
            $formatted_text = '';
        } else {
            if ( $textformat == 7 ) {
                $formatted_text = '<ul>' . "\n";
            } else {
                $formatted_text = '<ol>' . "\n";
            }
            foreach ( $lines as $line ) {
                $formatted_text .= '<li>' . $line . '</li>' . "\n";
            }
            if ( $textformat == 7 ) {
                $formatted_text .= '</ul>' . "\n";
            } else {
                $formatted_text .= '</ol>' . "\n";
            }
        }
    } elseif ( $textformat == 11 or $textformat == 12 or $textformat == 13 ) {
        if ( $textformat == 11 ) {
            $text_filter_name = 'markdown';
        } elseif ( $textformat == 12 ) {
            $text_filter_name = 'markdown_with_smartypants';
        } elseif ( $textformat == 13 ) {
            $text_filter_name = 'textile_2';
        }
        if ( $ctx->load_modifier( $text_filter_name ) ) {
            $mod = 'smarty_modifier_' . $text_filter_name;
            $formatted_text = $mod( $text );
        }
    } else {
        $formatted_text = $text;
    }
    return $formatted_text;
}
?>