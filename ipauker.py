import cgi
import xml.parsers.expat
from xml.sax import saxutils

from google.appengine.api import users
from google.appengine.ext import webapp
from google.appengine.ext import db
from google.appengine.ext.webapp.util import run_wsgi_app

class Card(db.Model):
    front_text = db.StringProperty(multiline=True)
    front_batch = db.IntegerProperty()
    front_timestamp = db.IntegerProperty()
    reverse_text = db.StringProperty(multiline=True)
    reverse_batch = db.IntegerProperty()
    reverse_timestamp = db.IntegerProperty()

class MainPage(webapp.RequestHandler):
    def get(self):
        self.response.out.write("""
        <html>
        <body>
        <form action="/upload" enctype="multipart/form-data" method="post">
          <div><input type="file" name="data" size="40"></div>
          <div><input type="submit" value="Upload"></div>
        </form>
        </body>
        </html>""")

TOP_LEVEL = 0
IN_BATCH = 1
IN_CARD = 2
IN_SIDE = 3
IN_TEXT = 4

class PaukerParser:
    state = TOP_LEVEL
    batch = -2
    cards = []
    front_text = None
    front_timestamp = None
    reverse_text = None
    reverse_batch = None
    reverse_timestamp = None
    text = None

    def start_element(self, name, attrs):
        if self.state == TOP_LEVEL and name == 'Batch':
            self.state = IN_BATCH
        elif self.state == IN_BATCH and name == 'Card':
            self.front = None
            self.back = None
            self.state = IN_CARD
        elif self.state == IN_CARD and name == 'FrontSide':
            self.front_batch = self.batch
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
        pass

    def end_element(self, name):
        if self.state == IN_BATCH and name == 'Batch':
            self.batch = self.batch + 1
            self.state = TOP_LEVEL
        elif self.state == IN_CARD and name == 'Card':
            self.cards.append(Card(front_text = self.front_text,
                                   front_batch = self.front_batch,
                                   front_timestamp = self.front_timestamp,
                                   reverse_text = self.reverse_text,
                                   reverse_batch = self.reverse_batch,
                                   reverse_timestamp = self.reverse_timestamp))
            self.state = IN_BATCH
        elif self.state == IN_SIDE and name == 'FrontSide':
            self.front_text = self.text
            self.state = IN_CARD
        elif self.state == IN_SIDE and name == 'ReverseSide':
            self.reverse_text = self.text
            self.state = IN_CARD
        elif self.state == IN_TEXT and name == 'Text':
            self.state = IN_SIDE
        pass

    def char_data(self, data):
        if self.state == IN_TEXT:
            self.text = self.text + data

    def parse(self, data):
        p = xml.parsers.expat.ParserCreate()
        p.StartElementHandler = self.start_element
        p.EndElementHandler = self.end_element
        p.CharacterDataHandler = self.char_data

        p.Parse(data, 1);

        return self.cards

class Upload(webapp.RequestHandler):
    def post(self):
        p = PaukerParser()
        cards = p.parse(self.request.get('data'))
        db.put(cards)
        self.redirect('/list')

class List(webapp.RequestHandler):
    def get(self):
        self.cards = Card.all()
        self.response.headers['Content-Type'] = 'text/xml'
        self.response.out.write('<cards version="0.1">\n')
        for card in self.cards:
            self.response.out.write('<card>\n')
            self.response.out.write('<front batch="%s" timestamp="%s">%s</front>\n' % \
                                    (card.front_batch, card.front_timestamp, saxutils.escape(card.front_text)))
            self.response.out.write('<reverse batch="%s" timestamp="%s">%s</reverse>\n' % \
                                    (card.reverse_batch, card.reverse_timestamp, saxutils.escape(card.reverse_text)))
            self.response.out.write('</card>\n')
        self.response.out.write('</cards>\n')

application = webapp.WSGIApplication(
                                     [('/', MainPage),
                                      ('/upload', Upload),
                                      ('/list', List)],
                                     debug=True)

def main():
  run_wsgi_app(application)

if __name__ == "__main__":
  main()
