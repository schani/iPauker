import cgi
import urllib
from xml.sax import saxutils

from google.appengine.api import users
from google.appengine.ext import webapp
from google.appengine.ext import db
from google.appengine.ext.webapp.util import run_wsgi_app

import parsers

class Lesson(db.Model):
    name = db.StringProperty(required=True, multiline=True)
    owner = db.UserProperty(required=True)
    version = db.IntegerProperty(required=True)

class Card(db.Model):
    lesson = db.ReferenceProperty(Lesson, required=True)
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
        if other.front_timestamp == None or other.front_timestamp > self.front_timestamp:
            self.front_batch = other.front_batch
            if other.front_timestamp != None:
                self.front_timestamp = other.front_timestamp
        if other.reverse_timestamp == None or other.reverse_timestamp > self.reverse_timestamp:
            self.reverse_batch = other.reverse_batch
            if other.reverse_timestamp != None:
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
            <p><a href="/lessons">Lessons</a></p>
            </body>
            </html>""")
        else:
            self.redirect(users.create_login_url(self.request.uri))

def get_lesson(user, lesson_name, create):
    lessons = Lesson.gql("WHERE name = :name AND owner = :owner", name=lesson_name, owner=user).fetch(1)
    if len(lessons) == 0:
        if not create:
            return None
        lesson = Lesson(name=lesson_name, owner=user, version=0)
        lesson.put()
        return lesson
    else:
        return lessons[0]

def make_diff(version, old_cards, new_cards, is_full_list):
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
    if is_full_list:
        for card in old_cards:
            if (not card.deleted) and (not touched_cards.has_key(card.hash_key())):
                card.deleted = True
                card.version = version
                diff_cards.append(card)
    return diff_cards

class UserRequestHandler(webapp.RequestHandler):
    def get(self):
        user = users.get_current_user()
        if user:
            self.get_with_user(user)
        else:
            self.redirect(users.create_login_url(self.request.uri))

    def post(self):
        user = users.get_current_user()
        if user:
            self.post_with_user(user)
        else:
            self.redirect(users.create_login_url(self.request.uri))

    def get_with_user(self, user):
        self.post_with_user(user)

class LessonRequestHandler(UserRequestHandler):
    def get_with_user(self, user):
        self.post_no_lesson()

    def post_with_user(self, user):
        lesson_name = self.request.get('lesson')
        if lesson_name:
            self.post_with_user_and_lesson(user, lesson_name)
        else:
            self.post_no_lesson()

class DiffRequestHandler(LessonRequestHandler):
    def post_with_user_and_lesson(self, user, lesson_name):
        lesson = get_lesson(user, lesson_name, True)
        lesson.version = lesson.version + 1

        new_cards = self.parse_diff_data(lesson, self.request.get('data'))

        current_cards = lesson.card_set

        diff_cards = make_diff(lesson.version, current_cards, new_cards, self.is_full_list())

        db.put(lesson)
        while len (diff_cards) > 0:
            db.put (diff_cards [:500])
            diff_cards = diff_cards [500:]

        self.response.out.write ('<html><body>OK</body></html>')

    def post_no_lesson(self):
        self.response.out.write("""
        <html>
        <body>
        <form action="%s" enctype="multipart/form-data" method="post">
        <div>Lesson: <input type="text" name="lesson"></div>
        <div>Pauker file: <input type="file" name="data" size="40"></div>
        <div><input type="submit" value="Diff"></div>
        </form>
        </body>
        </html>""" % self.request.uri)

class Upload(DiffRequestHandler):
    def parse_diff_data(self, lesson, data):
        p = parsers.PaukerParser(Card, db.Text, lesson)
        return p.parse(data)

    def is_full_list(self):
        return True

class Update(DiffRequestHandler):
    def parse_diff_data(self, lesson, data):
        p = parsers.CardsParser(Card, db.Text, lesson)
        return p.parse(data)

    def is_full_list(self):
        return False

class List(LessonRequestHandler):
    def post_with_user_and_lesson(self, user, lesson_name):
        lesson = get_lesson(user, lesson_name, False)
        diff_version = int(self.request.get('version'))
        self.response.headers['Content-Type'] = 'text/xml'
        if lesson:
            cards = Card.gql("WHERE lesson = :lesson AND version > :version",
                             lesson=lesson, version=diff_version)
            self.response.out.write('<cards format="0.1" version="%s">\n' % lesson.version)
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
            self.response.out.write('<cards format="0.1"></cards>\n')

    def post_no_lesson(self):
        self.response.out.write("""
        <html>
        <body>
        <form action="/list" method="post">
        <div>Lesson: <input type="text" name="lesson"></div>
        <div>Version: <input type="text" name="version"></div>
        <div><input type="submit" value="Show"></div>
        </form>
        </body>
        </html>""")

class Dump(LessonRequestHandler):
    def post_with_user_and_lesson(self, user, lesson_name):
        lesson = get_lesson(user, lesson_name, False)
        self.response.headers['Content-Type'] = 'text/xml'

        if not lesson:
            self.response.out.write("""<?xml version="1.0" encoding="UTF-8" standalone="no"?>
            <!--This is a lesson file for Pauker (http://pauker.sourceforge.net)-->
            <Lesson LessonFormat="1.7">
            <Description>%s by %s</Description>
            </Lesson>""" % (saxutils.escape(lesson_name), saxutils.escape(user.nickname())))
            return

        self.response.out.write("""<?xml version="1.0" encoding="UTF-8" standalone="no"?>
        <!--This is a lesson file for Pauker (http://pauker.sourceforge.net)-->
        <Lesson LessonFormat="1.7">
        <Description>%s version %d by %s</Description>""" % (saxutils.escape(lesson_name), lesson.version, saxutils.escape(user.nickname())))
        cards = Card.gql("WHERE lesson = :lesson AND deleted = FALSE", lesson=lesson)

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

    def post_no_lesson(self):
        self.response.out.write("""
        <html>
        <body>
        <form action="/dump" method="post">
        <div>Lesson: <input type="text" name="lesson"></div>
        <div><input type="submit" value="Show"></div>
        </form>
        </body>
        </html>""")

class Lessons(UserRequestHandler):
    def post_with_user(self, user):
        lessons = Lesson.gql("WHERE owner = :owner", owner=user)
        self.response.headers['Content-Type'] = 'text/xml'
        self.response.out.write('<lessons format="0.1">\n')
        for lesson in lessons:
            self.response.out.write('<lesson version="%s">%s</lesson>\n' %
                                    (lesson.version, saxutils.escape(lesson.name)))
        self.response.out.write('</lessons>\n')

application = webapp.WSGIApplication([('/', MainPage),
                                      ('/upload', Upload),
                                      ('/update', Update),
                                      ('/list', List),
                                      ('/dump', Dump),
                                      ('/lessons', Lessons)],
                                     debug=True)

def main():
  run_wsgi_app(application)

if __name__ == "__main__":
  main()
