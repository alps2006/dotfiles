# ABOUT
# This plugin gives format to tweet.im's bot messages, converting
# the @sender into the bot's nick and colorizing usernames, groups
# and hashtags.
#
# It's written for bitlbee, but should work with anything that permits
# the XMPP bot open a query buffer with you.
#
# HISTORY
# 2009-10-26, vern:
#		initial release

import weechat
import re
import urllib2
import simplejson as json

from base64 import encodestring
from urllib import urlencode
from random import randint


SCRIPT_NAME    = "tweetim"
SCRIPT_AUTHOR  = "Vern Sun <s5unty@gmail.com>"
SCRIPT_VERSION = "0.1"
SCRIPT_LICENSE = "GPL3"
SCRIPT_DESC    = "Formats tweet.im's bot messages. Derived from fauno identica.py-0.2"

settings = {
		"username"                : "",
		"password"                : "",
		"service"                 : "tweet.im",
		"scheme"                  : "https",
		"channel"                 : "localhost.update",
		"re"                      : "^(?P<update>\w+)(?P<separator>\W+?)(?P<nickname>[^\(]+) \((?P<username>\w+)\): (?P<dent>.+)$",

		"nick_color"              : "green",
		"hashtag_color"           : "blue",
		"group_color"             : "red",

		"nick_color_identifier"   : "blue",
		"hashtag_color_identifier": "green",
		"group_color_identifier"  : "green",

		"nick_re"                 : "(@)([a-zA-Z0-9]+)",
		"hashtag_re"              : "(#)([a-zA-Z0-9]+)",
		"group_re"                : "(!)([a-zA-Z0-9]+)"
		}

users = {}

class StatusNet():
	def __init__(self, username, password, scheme, service):

		self.username = username
		self.password = password

		self.realm    = 'Twitter API'
		self.service  = service
		self.scheme   = scheme

		self.opener = self.get_auth_opener()

	def get_auth_opener(self):
		'''Authentication'''
		basic_auth = encodestring(':'.join([self.username, self.password]))
		basic_auth = ' '.join(['Basic', basic_auth])

		handler = urllib2.HTTPBasicAuthHandler()
		handler.add_password(realm=self.realm,
		                     uri=self.service,
							 user=self.username,
							 passwd=self.password)
		
		self.headers = {'Authorization':basic_auth}
		return urllib2.build_opener(handler)

	def build_request(self, api_method, api_action, user_or_id, data={}):
		'''Builds an API request'''
		url = '%s://%s/api/%s/%s/%s.json' % (self.scheme,
		                                     self.service,
											 api_method,
											 api_action,
											 user_or_id)

		request = urllib2.Request(url, urlencode(data), self.headers)
		return request

	def handle_request(self, request):
		'''Sends an API request and handles errors'''
		try:
			response = self.opener.open(request)
		except urllib2.HTTPError, error:
			if error.code == 403:
				return False
			else:
				weechat.prnt(weechat.current_buffer(),
				             '%s[%s] Server responded with a %d error code' % (weechat.prefix('error'),
							                                                   self.service,
																			   error.code))
				return None
		else:
			return response

# End of StatusNet

def subscribe (username):
	if len(username) == 0:
		return weechat.WEECHAT_RC_ERROR

	response = statusnet_handler.handle_request(statusnet_handler.build_request('friendships', 'create', username))

	if response == None:
		pass
	elif response == False:
		weechat.prnt(weechat.current_buffer(), ('%sYou\'re already suscribed to %s' % (weechat.prefix('error'), username)))
	else:
		weechat.prnt(weechat.current_buffer(), response)
		weechat.prnt(weechat.current_buffer(), ('%sSuscribed to %s updates' % (weechat.prefix('join'), username)))

	return weechat.WEECHAT_RC_OK


def unsubscribe (username):
	if len(username) == 0:
		return weechat.WEECHAT_RC_ERROR

	response = statusnet_handler.handle_request(statusnet_handler.build_request('friendships', 'destroy', username))

	if response == None:
		pass
	elif response == False:
		weechat.prnt(weechat.current_buffer(), ('%sYou aren\'t suscribed to %s' % (weechat.prefix('error'), username)))
	else:
		weechat.prnt(weechat.current_buffer(), ('%sUnsuscribed from %s\'s updates' % (weechat.prefix('quit'), username)))
	
	return weechat.WEECHAT_RC_OK

def whois (username):
	if len(username) == 0:
		return weechat.WEECHAT_RC_ERROR
	
	response = statusnet_handler.handle_request(statusnet_handler.build_request('users', 'show', username))

	if response == None:
		pass
	elif response == False:
		weechat.prnt(weechat.current_buffer(), ('%sCan\'t retrieve information about %s' % (weechat.prefix('error'), username)))
	else:
		whois = json.load(response)

		for property in ['name', 'description', 'url', 'location']:
			if whois[property] != None:
				weechat.prnt(weechat.current_buffer(), ('%s[%s] %s' % (weechat.prefix('network'), username, whois[property].encode('utf-8'))))
		
	return weechat.WEECHAT_RC_OK

def block (username):
	'''Blocks users'''
	if len(username) == 0:
		return weechat.WEECHAT_RC_ERROR

	response = statusnet_handler.handle_request(statusnet_handler.build_request('blocks', 'create', username))

	if response == None:
		pass
	elif response == False:
		weechat.prnt(weechat.current_buffer(), ('%sCan\'t block %s' % (weechat.prefix('error'), username)))
	else:
		weechat.prnt(weechat.current_buffer(), ('%sBlocked %s' % (weechat.prefix('network'), username)))
		
	return weechat.WEECHAT_RC_OK


def unblock (username):
	'''Unblocks users'''
	if len(username) == 0:
		return weechat.WEECHAT_RC_ERROR

	response = statusnet_handler.handle_request(statusnet_handler.build_request('blocks', 'destroy', username))

	if response == None:
		pass
	elif response == False:
		weechat.prnt(weechat.current_buffer(), ('%sCan\'t unblock %s' % (weechat.prefix('error'), username)))
	else:
		weechat.prnt(weechat.current_buffer(), ('%sUnblocked %s' % (weechat.prefix('network'), username)))
		
	return weechat.WEECHAT_RC_OK


def colorize (message):
	"""Colorizes replies, hashtags and groups"""

	for identifier in ['nick','hashtag','group']:
		identifier_name = ''.join([identifier, '_re'])
		identifier_color = ''.join([identifier, '_color'])
		identifier_color_identifier = ''.join([identifier, '_color_identifier'])

		identifier_re = re.compile(weechat.config_get_plugin(identifier_name), re.UNICODE)

		replace = r''.join([
			weechat.color(weechat.config_get_plugin(identifier_color_identifier)),
			'\\1',
			weechat.color(weechat.config_get_plugin(identifier_color)),
			'\\2',
			weechat.color('reset')
			])

		message = identifier_re.sub(replace, message)

	return message

def nick_color (nick):
	"""Randomizes color for nicks"""
	if users.has_key(nick) and users[nick].has_key('color'):
		pass
	else:
		users[nick] = {}
		users[nick]['color'] = ''.join(['chat_nick_color', str(randint(1,10)).zfill(2)])

	nick = ''.join([weechat.color(users[nick]['color']), nick, weechat.color('reset')])
	return nick

def parse (server, modifier, data, the_string):
	"""Parses weechat_print modifier on s5unty@twitter.tweet.im pv"""

	plugin, channel, flags = data.split(';')

	if channel == weechat.config_get_plugin('channel'):

		the_string = weechat.string_remove_color(the_string, "")
		matcher = re.compile(weechat.config_get_plugin('re'), re.UNICODE)

		m = matcher.search(the_string)

		if not m: return colorize(re.sub("^x_twitter", "[^^^]", the_string))

		dent = colorize(m.group('dent'))
		username = nick_color(m.group('username'))

		the_string = ''.join([ weechat.color('cyan'), username, weechat.color('reset'), m.group('separator'), dent ])

	return the_string

def nicklist(data, completion_item, buffer, completion):
	"""Completion for /sn"""
	for username, properties in users.iteritems():
		weechat.hook_completion_list_add(completion, username, 0, weechat.WEECHAT_LIST_POS_SORT)
	return weechat.WEECHAT_RC_OK

def sn (data, buffer, args):
	if args == "":
		weechat.command("", "/help sn")
		return weechat.WEECHAT_RC_OK
	
	argv = args.strip().split(' ', 1)

	if argv[0] == 'subscribe':
		subscribe(argv[1])
	elif argv[0] == 'unsubscribe':
		unsubscribe(argv[1])
	elif argv[0] == 'whois':
		whois(argv[1])
	elif argv[0] == 'block':
		block(argv[1])
	elif argv[0] == 'unblock':
		unblock(argv[1])

	return weechat.WEECHAT_RC_OK
	
	

# init

if weechat.register(SCRIPT_NAME, SCRIPT_AUTHOR, SCRIPT_VERSION, SCRIPT_LICENSE,
		SCRIPT_DESC, "", ""):

	for option, default_value in settings.iteritems():
		if not weechat.config_is_set_plugin(option):
			weechat.config_set_plugin(option, default_value)

	username = weechat.config_get_plugin('username')
	password = weechat.config_get_plugin('password')
	service  = weechat.config_get_plugin('service')
	scheme   = weechat.config_get_plugin('scheme')
	
	if len(username) == 0 or len(password) == 0:
		weechat.prnt(weechat.current_buffer(),
		            '%s[%s] Please set your username and password and reload the plugin' % (weechat.prefix('error'),
					                                                                        service))
	else:
		statusnet_handler = StatusNet(username, password, scheme, service)

    # hook incoming messages
	weechat.hook_modifier('weechat_print', 'parse', '')

    # /sn
#	weechat.hook_command('sn',
#	                     'StatusNet manager',
#						 'whois | subscribe | unsubscribe | block | unblock <username>',
#						 '        whois: retrieves profile information from <username>'
#						 "\n"
#						 '    subscribe: subscribes to <username>'
#						 "\n"
#						 '  unsubscribe: unsubscribes from <username>'
#						 "\n"
#						 '        block: blocks <username>'
#						 "\n"
#						 '      unblock: unblocks <username>',
#						 'whois %(sn_nicklist) || sub %(sn_nicklist) || unsub %(sn_nicklist) || block %(sn_nicklist) || unblock %(sn_nicklist)',
#						 'sn',
#						 '')
#
#	# Completion for /sn commands
#	weechat.hook_completion('sn_nicklist', 'list of SN users', 'nicklist', '')

