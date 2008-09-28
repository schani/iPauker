import cgi
import xml.parsers.expat
import urllib
from xml.sax import saxutils

from google.appengine.api import users
from google.appengine.ext import webapp
from google.appengine.ext import db
from google.appengine.ext.webapp.util import run_wsgi_app

class Lession(db.Model):
    name = db.StringProperty(required=True, multiline=True)
    owner = db.UserProperty(required=True)
    version = db.IntegerProperty(required=True)

class Card(db.Model):
    lession = db.ReferenceProperty(Lession, required=True)
    front_text = db.TextProperty()
    front_batch = db.IntegerProperty(required=True)
    front_timestamp = db.IntegerProperty()
    reverse_text = db.TextProperty()
    reverse_batch = db.IntegerProperty(required=True)
    reverse_timestamp = db.IntegerProperty()

class MainPage(webapp.RequestHandler):
    def get(self):
        user = users.get_current_user()
        if user:
            self.response.out.write("""
            <html>
            <body>
            <form action="/upload" enctype="multipart/form-data" method="post">
            <div>Lession: <input type="text" name="lession"></div>
            <div>Pauker file: <input type="file" name="data" size="40"></div>
            <div><input type="submit" value="Upload"></div>
            </form>
            </body>
            </html>""")
        else:
            self.redirect(users.create_login_url(self.request.uri))

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

    def __init__(self, lession):
        self.lession = lession

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
            self.cards.append(Card(lession = self.lession,
                                   front_text = db.Text(self.front_text),
                                   front_batch = self.front_batch,
                                   front_timestamp = self.front_timestamp,
                                   reverse_text = db.Text(self.reverse_text),
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

def get_lession(user, lession_name, create):
    lessions = Lession.gql("WHERE name = :name AND owner = :owner", name=lession_name, owner=user).fetch(1)
    if len(lessions) == 0:
        if not create:
            return None
        lession = Lession(name=lession_name, owner=user, version=0)
        lession.put()
        return lession
    else:
        return lessions[0]

class Upload(webapp.RequestHandler):
    def post(self):
        user = users.get_current_user()
        lession_name = self.request.get('lession')
        if user and lession_name:
            lession = get_lession(user, lession_name, True)
            p = PaukerParser(lession)
            cards = p.parse(self.request.get('data'))
            db.put(cards)
            self.redirect('/list?lession=%s' % urllib.quote(lession_name))
        else:
            self.redirect(users.create_login_url('/'))

class List(webapp.RequestHandler):
    def get(self):
        user = users.get_current_user()
        lession_name = self.request.get('lession')
        if user and lession_name:
            lession = get_lession(user, lession_name, False)
            self.response.headers['Content-Type'] = 'text/xml'
            if lession:
                self.cards = Card.gql("WHERE lession = :lession", lession=lession).fetch(99999)
                self.response.out.write('<cards version="0.1">\n')
                for card in self.cards:
                    self.response.out.write('<card>\n')
                    self.response.out.write('<front batch="%s" timestamp="%s">%s</front>\n' % \
                                            (card.front_batch, card.front_timestamp, saxutils.escape(card.front_text)))
                    self.response.out.write('<reverse batch="%s" timestamp="%s">%s</reverse>\n' % \
                                            (card.reverse_batch, card.reverse_timestamp, saxutils.escape(card.reverse_text)))
                    self.response.out.write('</card>\n')
                self.response.out.write('</cards>\n')
            else:
                self.response.out.write('<cards version="0.1"></cards>\n')
        else:
            if user:
                self.response.out.write("""
                <html>
                <body>
                <form action="/list" method="get">
                <div>Lession: <input type="text" name="lession"></div>
                <div><input type="submit" value="Show"></div>
                </form>
                </body>
                </html>""")
            else:
                self.redirect(users.create_login_url(self.request.uri))

class Lessions(webapp.RequestHandler):
    def get(self):
        lessions = Lession.all()
        self.response.out.write('<html><body><pre>')
        for lession in lessions:
            self.response.out.write('%s   %s   %d\n' % (lession.name, lession.owner, lession.version))
        self.response.out.write('</pre></body></html>')

application = webapp.WSGIApplication(
                                     [('/', MainPage),
                                      ('/upload', Upload),
                                      ('/list', List),
                                      ('/lessions', Lessions)],
                                     debug=True)

def main():
  run_wsgi_app(application)

if __name__ == "__main__":
  main()
