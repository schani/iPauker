from xml.sax import saxutils

def write_cards (lesson, cards, write_func):
    if lesson:
        write_func ('<cards format="0.1" version="%s">\n' % lesson.version)
        for card in cards:
            if card.deleted:
                write_func ('<card deleted="True"><front>%s</front><reverse>%s</reverse></card>\n' % \
                                        (saxutils.escape(card.front_text),
                                         saxutils.escape(card.reverse_text)))
            else:
                write_func ('<card>\n')
                write_func ('<front batch="%s" timestamp="%s">%s</front>\n' % \
                                        (card.front_batch, card.front_timestamp,
                                         saxutils.escape(card.front_text)))
                write_func ('<reverse batch="%s" timestamp="%s">%s</reverse>\n' % \
                                        (card.reverse_batch, card.reverse_timestamp,
                                         saxutils.escape(card.reverse_text)))
                write_func ('</card>\n')
        write_func ('</cards>\n')
    else:
        write_func ('<cards format="0.1"></cards>\n')
