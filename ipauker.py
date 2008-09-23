import cgi
import xml.parsers.expat

from google.appengine.api import users
from google.appengine.ext import webapp
from google.appengine.ext.webapp.util import run_wsgi_app

class Card:
    def __init__(self, front_text, front_batch, reverse_text, reverse_batch):
        self.front_text = front_text
        self.front_batch = front_batch
        self.reverse_text = reverse_text
        self.reverse_batch = reverse_batch

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

class Upload(webapp.RequestHandler):
    state = TOP_LEVEL
    batch = -2
    cards = []
    front_text = None
    reverse_text = None
    reverse_batch = None
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
            self.text = ''
            self.state = IN_SIDE
        elif self.state == IN_CARD and name == 'ReverseSide':
            if attrs.has_key('Batch'):
                self.reverse_batch = int(attrs['Batch'])
            else:
                self.reverse_batch = -2
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
            self.cards.append(Card(self.front_text, self.front_batch, self.reverse_text, self.reverse_batch))
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

    def post(self):
        p = xml.parsers.expat.ParserCreate()
        p.StartElementHandler = self.start_element
        p.EndElementHandler = self.end_element
        p.CharacterDataHandler = self.char_data

        p.Parse(self.request.get('data'), 1);

        self.response.out.write('<html><body>You wrote:<pre>')
        for card in self.cards:
            self.response.out.write('%s   %d   %s   %d\n' % (card.front_text, card.front_batch, card.reverse_text, card.reverse_batch))
        #self.response.out.write(cgi.escape(self.request.get('data')))
        self.response.out.write('</pre></body></html>')

application = webapp.WSGIApplication(
                                     [('/', MainPage),
                                      ('/upload', Upload)],
                                     debug=True)

def main():
  run_wsgi_app(application)

if __name__ == "__main__":
  main()
