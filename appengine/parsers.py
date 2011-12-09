import xml.parsers.expat

TOP_LEVEL = 0
IN_BATCH = 1
IN_CARD = 2
IN_SIDE = 3
IN_TEXT = 4

class ParserBase:
    def __init__(self, card_constructor, blob_constructor, lesson):
        self.card_constructor = card_constructor
        self.blob_constructor = blob_constructor
        self.state = TOP_LEVEL
        self.cards = []
        self.front_batch = None
        self.front_text = None
        self.front_timestamp = None
        self.reverse_text = None
        self.reverse_batch = None
        self.reverse_timestamp = None
        self.text = None
        self.lesson = lesson

    def append_card(self):
        self.cards.append(self.card_constructor(lesson = self.lesson,
                                                version = self.lesson.version,
                                                deleted = False,
                                                front_text = self.blob_constructor(self.front_text),
                                                front_batch = self.front_batch,
                                                front_timestamp = self.front_timestamp,
                                                reverse_text = self.blob_constructor(self.reverse_text),
                                                reverse_batch = self.reverse_batch,
                                                reverse_timestamp = self.reverse_timestamp))

    def parse(self, data):
        p = xml.parsers.expat.ParserCreate()
        p.StartElementHandler = self.start_element
        p.EndElementHandler = self.end_element
        p.CharacterDataHandler = self.char_data

        p.Parse(data, 1);

        return self.cards

class PaukerParser(ParserBase):
    def __init__(self, card_constructor, blob_constructor, lesson):
        ParserBase.__init__(self, card_constructor, blob_constructor, lesson)
        self.front_batch = -2

    def start_element(self, name, attrs):
        if self.state == TOP_LEVEL and name == 'Batch':
            self.state = IN_BATCH
        elif self.state == IN_BATCH and name == 'Card':
            self.state = IN_CARD
        elif self.state == IN_CARD and name == 'FrontSide':
            if attrs.has_key('LearnedTimestamp'):
                self.front_timestamp = int(attrs['LearnedTimestamp']);
            else:
                self.front_timestamp = None
            self.text = ''
            self.state = IN_SIDE
        elif self.state == IN_CARD and name == 'ReverseSide':
            if attrs.has_key('Batch'):
                self.reverse_batch = int(attrs['Batch'])
            else:
                self.reverse_batch = -2
            if attrs.has_key('LearnedTimestamp'):
                self.reverse_timestamp = int(attrs['LearnedTimestamp']);
            else:
                self.reverse_timestamp = None
            self.text = ''
            self.state = IN_SIDE
        elif self.state == IN_SIDE and name == 'Text':
            self.state = IN_TEXT

    def end_element(self, name):
        if self.state == IN_BATCH and name == 'Batch':
            self.front_batch = self.front_batch + 1
            self.state = TOP_LEVEL
        elif self.state == IN_CARD and name == 'Card':
            self.append_card()
            self.state = IN_BATCH
        elif self.state == IN_SIDE and name == 'FrontSide':
            self.front_text = self.text
            self.state = IN_CARD
        elif self.state == IN_SIDE and name == 'ReverseSide':
            self.reverse_text = self.text
            self.state = IN_CARD
        elif self.state == IN_TEXT and name == 'Text':
            self.state = IN_SIDE

    def char_data(self, data):
        if self.state == IN_TEXT:
            self.text = self.text + data

class CardsParser(ParserBase):
    def start_element(self, name, attrs):
        if self.state == TOP_LEVEL and name == 'card':
            self.state = IN_CARD
        elif self.state == IN_CARD and name == 'front':
            self.front_batch = int(attrs['batch'])
            if not attrs.has_key('timestamp') or attrs['timestamp'] == 'None':
                self.front_timestamp = None
            else:
                self.front_timestamp = int(attrs['timestamp'])
            self.text = ''
            self.state = IN_SIDE
        elif self.state == IN_CARD and name == 'reverse':
            self.reverse_batch = int(attrs['batch'])
            if not attrs.has_key('timestamp') or attrs['timestamp'] == 'None':
                self.reverse_timestamp = None
            else:
                self.reverse_timestamp = int(attrs['timestamp'])
            self.text = ''
            self.state = IN_SIDE

    def end_element(self, name):
        if self.state == IN_CARD and name == 'card':
            self.append_card()
            self.state = TOP_LEVEL
        elif self.state == IN_SIDE and name == 'front':
            self.front_text = self.text
            self.state = IN_CARD
        elif self.state == IN_SIDE and name == 'reverse':
            self.reverse_text = self.text
            self.state = IN_CARD

    def char_data(self, data):
        if self.state == IN_SIDE:
            self.text = self.text + data
