import httpclient
import strformat
import random
import json
import uri
import re

import wNim/[
  wApp,
  wFrame,
  wPanel,
  wButton,
  wStaticText,
  wComboBox,
  wTextCtrl,
  wIcon
]

randomize()

const 
  shorteners = [
    "1pt",
    "GoTiny",
    "Short Link",
    "Shrtcode"
  ]
  ## The array of URL shorteners that the user can use

let
  urlRePattern = re"((([A-Za-z]{3,9}:(?:\/\/)?)(?:[-;:&=\+\$,\w]+@)?[A-Za-z0-9.-]+|(?:www.|[-;:&=\+\$,\w]+@)[A-Za-z0-9.-]+)((?:\/[\+~%\/.\w_]*)?\??(?:[-\+=&;%@.\w_]*)#?(?:[\w]*))?)"
  # from https://stackoverflow.com/a/8234912
  
var
  client = newHttpClient()

let app = App()
let frame = Frame(title="URL Shortener", size=(450, 500))
let panel = Panel(frame)

frame.disableMaximizeButton()
frame.setMinSize(450, 500)
frame.setMaxSize(450, 500) # set window to be unresizable

## Setup UI
let urlTitleLabel = StaticText(panel, label="Enter URL to shorten:", style=wAlignCentre or wAlignMiddle)
urlTitleLabel.move(165, 50)

let urlTextCtrl = TextCtrl(panel, style=wTeDontWrap or wTeRich or wBorderSimple)
urlTextCtrl.move(100, 100)
urlTextCtrl.setSize(245, 43)
urlTextCtrl.setBackgroundColor(0x00DCDCDC) 

let shortenerTitleLabel = StaticText(panel, label="Select which URL shortener to use")
shortenerTitleLabel.move(135, 215)

let shortenerComboBox = ComboBox(panel, choices=shorteners, value=sample(shorteners), style=wCbReadOnly or wCbSort)
shortenerComboBox.move(175, 235)

let shortenButton = Button(panel, label="Shorten URL!")
shortenButton.move(175, 400)

let shortenedUrlLabel = TextCtrl(panel, style=wTeReadOnly or wTeCenter)
shortenedUrlLabel.move(120, 325)
shortenedUrlLabel.setSize(200, 20)
#shortenedUrlLabel.setBackgroundColor(0x00AAAACC)

shortenButton.wEvent_Button do (): 
  let url = urlTextCtrl.getValue()

  if url == "":
    shortenedUrlLabel.clear()
    shortenedUrlLabel.add "Invalid URL"
    return
  elif match(url, urlRePattern) == false:
    shortenedUrlLabel.clear()
    shortenedUrlLabel.add "Invalid URL"
    return

  var 
    shortenedUrl: string 

  case shortenerComboBox.getValue(): 
    of "1pt":
      var
        response = client.getContent(parseUri("https://api.1pt.co/addURL") ? {"long": url})
        short = parseJson(response)["short"]

      shortenedUrl = "https://1pt.co/" & getStr(short)
    of "GoTiny":
      client.headers = newHttpHeaders({"Content-Type": "application/json"})

      var
        response = client.postContent("https://gotiny.cc/api", body=fmt"""{{"input": "{url}"}}""")

      shortenedUrl = "https://gotiny.cc/" & getStr(parseJson(response)[0]["code"])
    of "Short Link":
      var
        response = client.get(parseUri("https://short-link-api.vercel.app/") ? {"query": url}).body
        uris = ["chilp.it", "click.ru", "da.gd", "is.gd", "osdb.link", "ttm.sh"]
      
      shortenedUrl = (parseJson(response)[sample(uris)]).getStr()
    of "Shrtcode":
      var 
        response = client.get(parseUri("https://api.shrtco.de/v2/shorten") ? {"url": url}).body

      shortenedUrl = getStr(parseJson(response)["result"]["short_link"])
    else: 
      discard

  shortenedUrlLabel.setValue(shortenedUrl)

when isMainModule:
  frame.center()
  frame.show()
  frame.icon = Icon("icons/cut-scissor.ico")
  # Icon from https://uxwing.com/
  # Original icon URL: https://uxwing.com/cut-scissor-icon/

  app.mainLoop()
