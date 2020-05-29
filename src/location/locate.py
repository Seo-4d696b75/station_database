import sys
import re
import configparser
import math
import cv2
import numpy as np
import matplotlib.pyplot as plt
import os 
import glob
import shutil
import pyperclip
import subprocess
import datetime

# 設定の読み込み
config = configparser.ConfigParser()
config.read('config.ini')
pin_x = float(config.get('img', 'targetX'))
pin_y = float(config.get('img', 'targetY'))
clip_x = int(config.get('img', 'clipX'))
clip_y = int(config.get('img', 'clipY'))
clip_width = int(config.get('img', 'clipWidth'))
clip_height = int(config.get('img', 'clipHeight'))

target_zoom = float(config.get('map', 'zoom'))
margin_top = int(config.get('map', 'marginTop'))
margin_bottom = int(config.get('map', 'marginBottom'))
margin_left = int(config.get('map', 'marginLeft'))
margin_right = int(config.get('map', 'marginRight'))

code = int(sys.argv[1])

dir = config.get('map', 'des')
des = '%s/%d.png' % (dir,code)
map_file = des
if len(sys.argv) <= 2 or sys.argv[2] != '-n':
  files = glob.glob(config.get('map', 'pattern'))
  map_file = sorted(files, key= lambda s: os.stat(s).st_mtime)[len(files)-1]
  shutil.copyfile(map_file, des)

map = cv2.cvtColor(cv2.imread(des),cv2.COLOR_BGR2RGB)

head = cv2.cvtColor(cv2.imread(config.get('url','header')),cv2.COLOR_BGR2RGB)
foot = cv2.cvtColor(cv2.imread(config.get('url','footer')),cv2.COLOR_BGR2RGB)

res = cv2.matchTemplate(map, head, cv2.TM_CCOEFF)
min_val, max_val, min_loc, max_loc = cv2.minMaxLoc(res)
url_start = (max_loc[0] + head.shape[1], max_loc[1])
url = map[url_start[1]:url_start[1]+head.shape[0], url_start[0]:map.shape[1], :]
res = cv2.matchTemplate(url, foot, cv2.TM_CCOEFF)
min_val, max_val, min_loc, max_loc = cv2.minMaxLoc(res)
url_end = (url_start[0] + max_loc[0], url_start[1] + head.shape[0])
url = map[url_start[1]:url_end[1], url_start[0]:url_end[0], :]
cv2.imwrite('string.png', url)
proc = subprocess.run('tesseract string.png stdout'.split(), stdout=subprocess.PIPE)
string = re.sub('\s','',proc.stdout.decode('utf-8'))

while True:
  m = re.match('([0-9\.]+),([0-9\.]+),([0-9\.]+)', string)
  if m:
    break
  print('fail to convert coordicate: %s' % string)
  pyperclip.copy(string)
  string = input('put correct value: ')
center_lat = float(m.group(1))
center_lng = float(m.group(2))
zoom = float(m.group(3))

print("map: %s\nlng:%.7f, lat:%.7f zoom:%.2f" % (map_file, center_lng, center_lat, zoom))


print('Clip zie :[%d:%d, %d:%d]' % (clip_y, clip_y + clip_height, clip_x, clip_x + clip_width))

h,w,c = map.shape

'''
経度（緯線）方向に関するデバイスpixel単位あたりの経度
dθ/dx = 1/R (const.)より緯度に依らず単純な比例関係で計算できる
経度±180[deg]がpixel coordinate の値域[0,256*2^target_zoom]に対応する
ただし pixel coordinate はDOMにおけるサイズのdip単位'px'に対応するから
画像上のピクセル単位に合わせる必要がある
'''
unit = 360 / (256 * math.pow(2, target_zoom)) / float(config.get('map', 'density'))

map = map[margin_top:(h-margin_bottom), margin_left:(w-margin_right), :]
map_x = w/2 - margin_left
map_y = (h - margin_top - margin_bottom)/2
scale = math.pow(2, target_zoom - zoom)
h,w,c = map.shape
h = int(h * scale)
w = int(w * scale)
map_x *= scale
map_y *= scale
map = cv2.resize(map, dsize=(w,h))


img_file = '%s/%d.jpg' % (config.get('img','src'), code)
print('img : %s' % img_file)
img = cv2.cvtColor(cv2.imread(img_file),cv2.COLOR_BGR2RGB)
img = img[clip_y:(clip_y+clip_height), clip_x:(clip_x+clip_width), :]
pin = cv2.cvtColor(cv2.imread(config.get('img','pin')), cv2.COLOR_BGR2RGB)
res = cv2.matchTemplate(img, pin, cv2.TM_CCOEFF)
min_val, max_val, min_loc, max_loc = cv2.minMaxLoc(res)
pin_x += max_loc[0]
pin_y += max_loc[1]

res = cv2.matchTemplate(map, img, cv2.TM_CCOEFF)
min_val, max_val, min_loc, max_loc = cv2.minMaxLoc(res)
top_left = max_loc
bottom_right = (top_left[0] + clip_width, top_left[1] + clip_height)
extract = map.copy()[top_left[1]:bottom_right[1], top_left[0]:bottom_right[0], :]
cv2.rectangle(map,top_left, bottom_right, 255, 10)

def grad(p, res, size, point):
  sum = np.array([0,0,0,0,0])
  for dx in range(-size//2,size//2+1,1):
    for dy in range(-size//2,size//2+1,1):
      x = point[0] + dx
      y = point[1] + dy
      z = res[y,x]
      a = p[0]*(x-p[1])**2 + p[2]*(y-p[3])**2 + p[4] - z
      sum = sum + np.array([
        2*a*(x-p[1])**2,
        -4*a*p[0]*(x-p[1]),
        2*a*(y-p[3])**2,
        -4*a*p[2]*(y-p[3]),
        2*a
      ])
  len = np.linalg.norm(sum)
  return sum / len

def sse(p, res, size, point):
  sum = 0
  for dx in range(-size//2,size//2+1,1):
    for dy in range(-size//2,size//2+1,1):
      x = point[0] + dx
      y = point[1] + dy
      z = res[y,x]
      sum += (p[0]*(x-p[1])**2 + p[2]*(y-p[3])**2 + p[4] - z)**2
  return sum


x,y = top_left
'''
# 移動幅固定の最急降下法で最適化問題を解く
size = 9
step = 0.01
# initialize params
p1 = (res[y,x-1] + res[y,x+1] - res[y,x]*2)/2
p3 = (res[y-1,x] + res[y+1,x] - res[y,x]*2)/2
p2 = x
p4 = y
p5 = res[y,x]
p = np.array([p1,p2,p3,p4,p5])

previous = sse(p, res, size, top_left)


while True:
  dp = grad(p, res, size, top_left) * (-1 * step) 
  p = p + dp
  next = sse(p, res, size, top_left)
  if abs(next/previous -1) < 0.01:
    break
  previous = next


point = (p[1],p[3])
print('subpixel estimate: %s -> %s' % (str(top_left),str(point) ))
'''

#x = point[0] + pin_x
#y = point[1] + pin_y
x += pin_x
y += pin_y

lng = center_lng + (x - map_x) * unit
lat = center_lat - (y - map_y) * unit * math.cos(center_lat / 180 * math.pi)

print('code:%d lat:%.6f lng:%.6f' % (code,lat,lng))
pyperclip.copy('%.6f,%.6f' % (lat,lng))

f = open('log.txt', encoding='utf-8', mode='a')
f.write('%s code:%d lat:%.6f lng:%.6f\n' % (datetime.datetime.now(), code, lat, lng))
f.close()

plt.subplot(221)
plt.imshow(res)
plt.title('Reuslt')
plt.subplot(222)
plt.imshow(img)
plt.title('Templete')
plt.subplot(223)
plt.imshow(map)
plt.title('Map')
plt.subplot(224)
plt.imshow(extract)
plt.title('Match')
plt.show()