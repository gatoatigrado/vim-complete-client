# vim-complete-client

Simple proxy that feeds autocomplete requests to an external server (for easier development &amp; persistent indexes). It's currently just a proof-of-concept.

## Installation (OS X)

Install some dependencies,

```
brew install macvim --with-cscope --with-lua
brew linkapps macvim
sudo luarocks install luasocket
sudo luarocks install lua-cjson
```

Download the plugin, e.g. `wget -O ~/.vim/complete-client.vim https://raw.githubusercontent.com/gatoatigrado/vim-complete-client/master/complete-client.vim`.

Add the following to your `~/.vimrc` (the last block/line is optional),

```
so ~/.vim/complete-client.vim

" Call the complete function. NOTE that in the future, on-keypress (TextChangeI) events
" could be intercepted and sent to the server (for cache warming or such)
set completefunc=CompleteClientOnCompletion

" Replace <C-n> if you're used to using that ...
" cf. http://vimhelp.appspot.com/insert.txt.html#ins-completion
inoremap <C-n> <C-X><C-U>
```

## Getting a server running

After you've completed the above, whenever you press `<C-X><C-U>`, vim should be sending requests to `http://localhost:18013/complete`. You can override this by setting the environment variable `VIM_AUTOCOMPLETE_SERVER_URL`.

To actually start a server on this URL, you can write a minimal Flask app (save this as `server.py` anywhere, and run it like `python server.py`),

```
from __future__ import absolute_import
from __future__ import print_function

import flask
import re
import simplejson
from collections import namedtuple

app = flask.Flask(__name__)


AutocompleteRequest = namedtuple("AutocompleteRequest", [
    "current_line",
    "current_column",
    "lines",
    "word_being_completed"
])


SPACES_RE = re.compile(ur'[^\w\d]+')
def simple_buffer_complete(request):
    words = SPACES_RE.split("\n".join(request.lines))
    words = (w.strip() for w in words)
    words = [w for w in words if w]
    return [w for w in words if w.startswith(request.word_being_completed)]


@app.route('/complete')
def complete():
    body = flask.request.get_json(force=True)
    request = AutocompleteRequest(**body)
    basics = simple_buffer_complete(request)
    
    result = simple_buffer_complete(request)[:10]
    return simplejson.dumps(result)


if __name__ == '__main__':
    app.run(host='127.0.0.1', port=18013, debug=True)
```

Cool. When you use auto-complete in `vim`, you should now see requests being sent to the server. A list of more interesting autocomplete servers will be coming shortly!
