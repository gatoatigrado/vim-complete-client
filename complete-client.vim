" zora tung <gatoatigrado@gmail.com>
" helpful stuff for if you want to hack on vim completion
" Apache 2 license
"
" installation (OS X):
"
" brew install macvim --with-cscope --with-lua
" brew linkapps macvim
" sudo luarocks install luasocket
" sudo luarocks install lua-cjson

function! CompleteClientOnCompletion(findstart, base)
    if a:findstart
      " locate the start of the word
      let line = getline('.')
      let start = col('.') - 1
      while start > 0 && line[start - 1] =~ '\a'
        let start -= 1
      endwhile
      return start
    else
        let results = [ ]
    lua << EOF
        local http = require("socket.http")
        local cjson = require("cjson.safe")

        local server_url = os.getenv("VIM_AUTOCOMPLETE_SERVER_URL")
        if not server_url then
            server_url = "http://localhost:18013/complete"
        end

        local base = vim.eval('a:base')
        local results = vim.eval('results')
        local window = vim.window()

        -- convert buffer to table for json serialization
        local buffer = vim.buffer()
        local buffer_as_table = {}
        for i = 1, #buffer do
            buffer_as_table[i] = buffer[i]
        end

        local reqbody = cjson.encode {
            word_being_completed = base,
            lines = buffer_as_table,
            -- the rest of the world uses 0-based indexing
            current_line = window.line - 1,
            current_column = window.column - 1
        }
        local headers = {
          ["Accept"] = "*/*",
          ["Accept-Encoding"] = "gzip, deflate",
          ["Accept-Language"] = "en-us",
          ["Content-Type"] = "application/x-www-form-urlencoded",
          ["content-length"] = string.len(reqbody)
        }
        local respbody = {}
        local client, code, headers, status = http.request {
            method = "GET",
            url = server_url,
            source = ltn12.source.string(reqbody),
            headers = headers,
            sink = ltn12.sink.table(respbody)
        }

        -- Add this if you want to force-add the prefix being completed ...
        -- results:add(base)

        if code ~= 200 then
            results:add(base)
            results:add(string.format("Request failed with status: %s", status))
        else
            local real_results = cjson.decode(table.concat(respbody))
            for i = 1, #real_results do
                results:add(real_results[i])
            end
        end
EOF
        return results
    endif
endfunction

if !(has('lua') && (v:version > 703 || v:version == 703 && has('patch885')))
    echomsg 'complete-client requires Vim 7.3.885 or later with Lua support ("+lua").'
endif
