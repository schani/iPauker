import cgi
import xml.parsers.expat

from google.appengine.api import users
from google.appengine.ext import webapp
from google.appengine.ext.webapp.util import run_wsgi_app

class CardSide:
    def __init__(self, text, batch):
        self.text = text
        self.batch = batch

class Card:
    def __init__(self, front, reverse):
        self.front = front
        self.reverse = reverse

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
    front = None
    reverse = None
    text = None

    def start_element(self, name, attrs):
        if self.state == TOP_LEVEL and name == 'Batch':
            self.state = IN_BATCH
        elif self.state == IN_BATCH and name == 'Card':
            self.front = None
            self.back = None
            self.state = IN_CARD
        elif self.state == IN_CARD and name == 'FrontSide':
            self.text = ''
            self.state = IN_SIDE
        elif self.state == IN_CARD and name == 'ReverseSide':
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
            self.cards.append(Card(self.front, self.reverse))
            self.state = IN_BATCH
        elif self.state == IN_SIDE and name == 'FrontSide':
            self.front = CardSide(self.text, self.batch)
            self.state = IN_CARD
        elif self.state == IN_SIDE and name == 'ReverseSide':
            self.reverse = CardSide(self.text, self.batch)
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
            self.response.out.write('%s   %d   %s   %d\n' % (card.front.text, card.front.batch, card.reverse.text, card.reverse.batch))
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
