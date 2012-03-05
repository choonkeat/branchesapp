cd public
echo '<!DOCTYPE html PUBLIC "-//W3C//DTD XHTML 1.0 Transitional//EN" "http://www.w3.org/TR/xhtml1/DTD/xhtml1-transitional.dtd">
<html lang="en" xmlns:og="http://ogp.me/ns#">
  <head>
    <link href="gritnet.css" media="screen" rel="stylesheet" type="text/css" />
  </head>
  <body>
    <h1><sup>git</sup><sub>hub</sub><sup>net</sup><sub>work</sub></h1>
' > index.html
for x in */*/index.html; do p=`dirname $x`; echo "<li><a href='${p}/'>${p}</a></li>"; done >> index.html
echo "<p><a href='mailto:contactme@choonkeat.com'>contact me</a></p></body></html>" >> index.html
cd -
