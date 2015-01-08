import sys, re
from selenium import webdriver

if len(sys.argv) < 2:
    print "Run with a URL to visit"
    sys.exit(1)

def fetch(url, cap):
  filename = re.sub(r'[^a-zA-Z0-9-]+', '', url) + "_" + re.sub(r'[^a-zA-Z0-9-]+', '', cap['browserName']) + "_" + str(cap['version']) + ".png"
  print cap
  driver = webdriver.Remote("http://localhost:4444/wd/hub", cap)
  driver.get(url)
  if driver.capabilities['takesScreenshot']:
      driver.get_screenshot_as_file(filename)
  else:
      print "Screenshots not supported by this browser"
  driver.close()
  driver.quit()

caps = []
for version in [8, 9, 10, 11]:
  cap = webdriver.DesiredCapabilities.INTERNETEXPLORER.copy()
  cap['version'] = version
  caps.append(cap)

#cap = webdriver.DesiredCapabilities.FIREFOX.copy()
#caps.append(cap)
#caps = []
#cap = webdriver.DesiredCapabilities.CHROME.copy()
#caps.append(cap)

for cap in caps:
    fetch(sys.argv[1],cap)
