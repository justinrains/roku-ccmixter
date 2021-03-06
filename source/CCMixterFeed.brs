Function loadFeed()
   avatars = CreateObject("roAssociativeArray")
   
   aa = CreateObject("roAssociativeArray")
   aa.posteritems = CreateObject("roArray", 10, true)
   feedUrl = "http://ccmixter.org/api/query?datasource=topics&type=podcast&page=podcast&f=rss"
   
   http = NewHttp(feedUrl)

   rsp = http.GetToStringWithRetry()

   xml=CreateObject("roXMLElement")
   if not xml.Parse(rsp) then
        print "Can't parse feed"
       return invalid
   endif
   
   For Each item In xml.channel.item
      title = item.title.GetText()
      author = item.GetNamedElements("dc:creator").GetText()
      description = extractDescription(item.GetNamedElements("content:encoded").GetText())
      file = item.enclosure@url
      releaseDate = formatDate(item.pubDate.GetText())
      length = extractLength(item.GetNamedElements("content:encoded").GetText())
      userName = findUserName(item.GetNamedElements("content:encoded").GetText())
      avatars = updateAvatars(avatars, userName)
      image = avatars[userName]
      licence = formatLicence(item.GetNamedElements("cc:license").GetText())
      song = CreateSong(title,author,description,"mp3", file, image, releaseDate, length, licence)
      aa.posteritems.push(song)
   End For
   
   return aa 
End Function

Function extractDescription(description As String)
   reEle = CreateObject("roRegex", "<[^>]*>", "")
   reApost = CreateObject("roRegex", "\&\#8217;", "")
   reWhiteSpace = CreateObject("roRegex", "^[ \t]+|[ \t]+$", "")
   reEllipsis = CreateObject("roRegex", "&#8230;", "")
   reEM = CreateObject("roRegex", "&#8212;", "")
   reLF = CreateObject("roRegex", "\n|\r\n|\n\r|\r", "")
   reLFStar = CreateObject("roRegex", "\*[A-Z]", "")
   reQuot = CreateObject("roRegex", "&#822[0-1];", "")
   reExcessSpace = CreateObject("roRegex", " {2,}", "")

   descMarker = instr(0, description, "gd_description")
 
   startDesc = instr(descMarker, description, ">") + 1
   endDesc = instr(startDesc, description, "</div>")
   description = Mid(description, startDesc, endDesc - startDesc)
   description = reLF.ReplaceAll(description, " ")
   description = reLFStar.ReplaceAll(description, "\n")
   description = reEle.ReplaceAll(description, "")
   description = reEM.ReplaceAll(description, "-")
   description = reApost.ReplaceAll(description, "'")
   description = reWhiteSpace.ReplaceAll(description, "")
   description = reEllipsis.ReplaceAll(description, "")
   description = reQuot.ReplaceAll(description, chr(22))
   description = reExcessSpace.ReplaceAll(description, " ")
  
   return description
End Function

Function extractLength(text As String)
   length = 0
    
   ' 19 is length of tag we are looking for
   duraMarker = instr(0, text, "enclosure_duration%") + 19
   endMarker = instr(duraMarker, text, "%") 
   If endMarker - duraMarker > 1 Then
       colonMarker = instr(duraMarker, text, ":")
       if colonMarker > 1 Then
           mins = mid(text, duraMarker, colonMarker - duraMarker).ToInt()
           secs = mid(text, colonMarker+1, endMarker - colonMarker -1).ToInt()
           length = (mins *60) + secs
       End If
   End If
   
   return length
End Function

Function findUserName(text As String) 
   startMarker = Instr(0,text, "http://ccmixter.org/people/")
   if startMarker > 0 Then
       endQuotMarker = Instr(startMarker, text, ">")
       return Mid(text, startMarker + 27, endQuotMarker - startMarker - 28)
   End If
   return ""
End Function

Function askCCMixterForUserAvatar(userName as String)
   reStart = CreateObject("roRegex", "\<img src=", "")
   imageUrl = "pkg:/images/ccMpromo.png"
   url = "http://ccmixter.org/api/query?limit=page&f=html&t=avatar&u=" + userName
   http = NewHttp(url)
   rsp = http.GetToStringWithRetry()
   if left(rsp, 4) = "<img" Then
       imageUrl = Mid(rsp, 11, Len(rsp) - 14)
   End If
   return imageUrl
End Function

Function updateAvatars(avatars As Object, userName as String)
   If Not avatars.DoesExist(userName) Then
       avatars[userName] = askCCMixterForUserAvatar(userName)
   End If
   return avatars
End Function

Function formatLicence(url As string)
    abbr = ""
    ccl_url = "http://creativecommons.org/licenses/"
    if Left(url, Len(ccl_url)) = ccl_url Then
        endMarker = Instr(len(ccl_url)+1, url, "/")
        abbr = "CC-" + UCase(Mid(url, Len(ccl_url)+1, endMarker - Len(ccl_url)-1))
    End IF
    return abbr
End Function

Function formatDate(date As String)
    return Left(date, 16)
End Function