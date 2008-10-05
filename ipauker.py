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
    version = db.IntegerProperty(required=True)
    deleted = db.BooleanProperty(required=True)
    front_text = db.TextProperty()
    front_batch = db.IntegerProperty(required=True)
    front_timestamp = db.IntegerProperty()
    reverse_text = db.TextProperty()
    reverse_batch = db.IntegerProperty(required=True)
    reverse_timestamp = db.IntegerProperty()

    def hash_key(self):
        return (self.front_text, self.reverse_text)

    def equals(self, other):
        return self.front_text == other.front_text and \
               self.front_batch == other.front_batch and \
               self.front_timestamp == other.front_timestamp and \
               self.reverse_text == other.reverse_text and \
               self.reverse_batch == other.reverse_batch and \
               self.reverse_timestamp == other.reverse_timestamp

    def take_values_from(self, other):
        self.version = other.version
        self.deleted = other.deleted
        self.front_text = other.front_text
        self.front_batch = other.front_batch
        self.front_timestamp = other.front_timestamp
        self.reverse_text = other.reverse_text
        self.reverse_batch = other.reverse_batch
        self.reverse_timestamp = other.reverse_timestamp

class MainPage(webapp.RequestHandler):
    def get(self):
        user = users.get_current_user()
        if user:
            self.response.out.write("""
            <html>
            <body>
            <p><a href="/upload">Upload</a></p>
            <p><a href="/list">List</a></p>
            <p><a href="/dump">Dump</a></p>
            <p><a href="/lessions">Lessions</a></p>
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
    def __init__(self, lession):
        self.state = TOP_LEVEL
        self.batch = -2
        self.cards = []
        self.front_text = None
        self.front_timestamp = None
        self.reverse_text = None
        self.reverse_batch = None
        self.reverse_timestamp = None
        self.text = None
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
                                   version = self.lession.version,
                                   deleted = False,
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

def make_diff(version, old_cards, new_cards):
    old_cards_hash = {}
    new_cards_hash = {}
    diff_cards = []
    touched_cards = {}
    for card in old_cards:
        old_cards_hash[card.hash_key()] = card
    for card in new_cards:
        # ignore duplicate cards
        if new_cards_hash.has_key(card.hash_key()):
            continue
        new_cards_hash[card.hash_key()] = True
        if old_cards_hash.has_key(card.hash_key()):
            old_card = old_cards_hash[card.hash_key()]
            if not card.equals(old_card):
                old_card.take_values_from(card)
                old_card.version = version
                diff_cards.append(old_card)
            elif old_card.deleted:
                old_card.deleted = False
                old_card.version = version
                diff_cards.append(old_card)
            touched_cards[old_card.hash_key()] = True
        else:
            diff_cards.append(card)
    for card in old_cards:
        if (not card.deleted) and (not touched_cards.has_key(card.hash_key())):
            card.deleted = True
            card.version = version
            diff_cards.append(card)
    return diff_cards

class LessionRequestHandler(webapp.RequestHandler):
    def get(self):
        self.postNoLession()

    def post(self):
        user = users.get_current_user()
        lession_name = self.request.get('lession')
        if user and lession_name:
            self.postWithUserAndLession(user, lession_name)
        elif user:
            self.postNoLession()
        else:
            self.redirect(users.create_login_url(self.request.uri))

class Upload(LessionRequestHandler):
    def postWithUserAndLession(self, user, lession_name):
        lession = get_lession(user, lession_name, True)
        lession.version = lession.version + 1

        p = PaukerParser(lession)
        new_cards = p.parse(self.request.get('data'))

        current_cards = lession.card_set

        diff_cards = make_diff(lession.version, current_cards, new_cards)

        self.response.out.write('<html><body><pre>')
        for card in diff_cards:
            self.response.out.write('%s    %s    %d   %s\n' % (card.front_text, card.reverse_text,
                                                               card.version, card.deleted))
        self.response.out.write('</pre></body></html>')

        db.put(lession)
        db.put(diff_cards)

    def postNoLession(self):
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

class List(LessionRequestHandler):
    def postWithUserAndLession(self, user, lession_name):
        lession = get_lession(user, lession_name, False)
        diff_version = int(self.request.get('version'))
        self.response.headers['Content-Type'] = 'text/xml'
        if lession:
            cards = Card.gql("WHERE lession = :lession AND version > :version", lession=lession, version=diff_version)
            self.response.out.write('<cards version="0.1">\n')
            for card in cards:
                if card.deleted:
                    self.response.out.write('<card deleted="True"><front>%s</front><reverse>%s</reverse></card>\n' % \
                                            (saxutils.escape(card.front_text),
                                             saxutils.escape(card.reverse_text)))
                else:
                    self.response.out.write('<card>\n')
                    self.response.out.write('<front batch="%s" timestamp="%s">%s</front>\n' % \
                                            (card.front_batch, card.front_timestamp,
                                             saxutils.escape(card.front_text)))
                    self.response.out.write('<reverse batch="%s" timestamp="%s">%s</reverse>\n' % \
                                            (card.reverse_batch, card.reverse_timestamp,
                                             saxutils.escape(card.reverse_text)))
                    self.response.out.write('</card>\n')
            self.response.out.write('</cards>\n')
        else:
            self.response.out.write('<cards version="0.1"></cards>\n')

    def postNoLession(self):
        self.response.out.write("""
        <html>
        <body>
        <form action="/list" method="post">
        <div>Lession: <input type="text" name="lession"></div>
        <div>Version: <input type="text" name="version"></div>
        <div><input type="submit" value="Show"></div>
        </form>
        </body>
        </html>""")

class Dump(LessionRequestHandler):
    def postWithUserAndLession(self, user, lession_name):
        lession = get_lession(user, lession_name, False)
        self.response.headers['Content-Type'] = 'text/xml'

        if not lession:
            self.response.out.write("""<?xml version="1.0" encoding="UTF-8" standalone="no"?>
            <!--This is a lesson file for Pauker (http://pauker.sourceforge.net)-->
            <Lesson LessonFormat="1.7">
            <Description>%s by %s</Description>
            </Lesson>""")
            return

        self.response.out.write("""<?xml version="1.0" encoding="UTF-8" standalone="no"?>
        <!--This is a lesson file for Pauker (http://pauker.sourceforge.net)-->
        <Lesson LessonFormat="1.7">
        <Description>%s by %s</Description>""" % (saxutils.escape(lession_name), saxutils.escape(user.nickname())))
        cards = Card.gql("WHERE lession = :lession AND deleted = FALSE", lession=lession)

        max_batch = -2
        batches = {}
        for card in cards:
            max_batch = max(max_batch, card.front_batch)

            if not batches.has_key(card.front_batch):
                batches[card.front_batch] = []
            batches[card.front_batch].append(card)

        for batch in range(-2, max_batch + 1):
            if not batches.has_key(batch):
                self.response.out.write("<Batch/>\n")
                continue
            cards = batches[batch]
            self.response.out.write("<Batch>\n")
            for card in cards:
                self.response.out.write("""
                <Card>
                <FrontSide %s Orientation="LTR" RepeatByTyping="false">
                <Text>%s</Text>
                </FrontSide>
                <ReverseSide %s Orientation="LTR" RepeatByTyping="false">
                <Text>%s</Text>
                </ReverseSide>
                </Card>""" % (("LearnedTimestamp=\"%d\"" % card.front_timestamp) if card.front_batch > 0 else "",
                              saxutils.escape(card.front_text),
                              ("Batch=\"%d\" LearnedTimestamp=\"%d\"" % (card.reverse_batch, card.reverse_timestamp)) if card.reverse_batch > 0 else "",
                              saxutils.escape(card.reverse_text)))
            self.response.out.write("</Batch>\n")

        self.response.out.write("</Lesson>")

    def postNoLession(self):
        self.response.out.write("""
        <html>
        <body>
        <form action="/dump" method="post">
        <div>Lession: <input type="text" name="lession"></div>
        <div><input type="submit" value="Show"></div>
        </form>
        </body>
        </html>""")

class Lessions(webapp.RequestHandler):
    def get(self):
        lessions = Lession.all()
        self.response.out.write('<html><body><pre>')
        for lession in lessions:
            self.response.out.write('%s   %s   %d\n' % (lession.name, lession.owner, lession.version))
        self.response.out.write('</pre></body></html>')

application = webapp.WSGIApplication([('/', MainPage),
                                      ('/upload', Upload),
                                      ('/list', List),
                                      ('/dump', Dump),
                                      ('/lessions', Lessions)],
                                     debug=True)

def main():
  run_wsgi_app(application)

if __name__ == "__main__":
  main()
