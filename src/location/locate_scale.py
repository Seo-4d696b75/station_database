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

# 地図画像の読み込み
dir = config.get('map', 'des')
des = '%s/%d.png' % (dir, code)
map_file = des
if len(sys.argv) <= 2 or sys.argv[2] != '-n':
    files = glob.glob(config.get('map', 'pattern'))
    map_file = sorted(files, key=lambda s: os.stat(s).st_mtime)[len(files)-1]
    shutil.copyfile(map_file, des)

map = cv2.cvtColor(cv2.imread(des), cv2.COLOR_BGR2RGB)

# 地図中心の座標値を含むURL文字列の位置を検出
head = cv2.cvtColor(cv2.imread(config.get('url', 'header')), cv2.COLOR_BGR2RGB)
res = cv2.matchTemplate(map, head, cv2.TM_CCOEFF)
min_val, max_val, min_loc, max_loc = cv2.minMaxLoc(res)
url_start = (max_loc[0] + head.shape[1], max_loc[1])
# 長さ400pxで切り取り
url = map[url_start[1]:url_start[1]+head.shape[0],
          url_start[0]:url_start[0]+400, :]
cv2.imwrite('string.png', url)
# OCRで文字列を判定
proc = subprocess.run(
    'tesseract string.png stdout'.split(), stdout=subprocess.PIPE)
string = re.sub('\s', '', proc.stdout.decode('utf-8'))
print(f"string: {string}")

while True:
    m = re.match('([0-9\.]+)/([0-9\.]+)/([0-9\.]+)(&.*)?', string)
    if m:
        break
    print(f"fail to convert coordicate: {string}")
    print('expected value: ${zoom}/${lat}/${lng}')
    pyperclip.copy(string)
    string = input('put correct value: ')
center_lat = float(m.group(2))
center_lng = float(m.group(3))
zoom = float(m.group(1))

print("map: %s\nlng:%.7f, lat:%.7f zoom:%.2f" %
      (map_file, center_lng, center_lat, zoom))

# 余計なmaringを除去
h, w, _ = map.shape
map = map[margin_top:(h-margin_bottom), margin_left:(w-margin_right), :]
# 既知の座標値が指すピクセル位置
map_x = w/2 - margin_left
map_y = (h - margin_top - margin_bottom)/2


def detect_rect(fig, ax, img, event, dst):
    if event.button == 1:
        return
    x = round(event.xdata)
    y = round(event.ydata)
    img_hsv = cv2.cvtColor(img, cv2.COLOR_RGB2HSV)
    diff = 100
    h, w, _ = img.shape
    mask = np.zeros((h + 2, w + 2), dtype=np.uint8)
    _, selected, mask, rect = cv2.floodFill(
        img.copy(), mask, (x, y,), (0, 255, 255,), diff, diff)
    ax.cla()
    ax.imshow(selected)
    ax.plot([x], [y], marker="+", color="red", markersize=20)
    fig.canvas.draw()
    np.copyto(dst, rect)
    print(f"onclick x:{x} y:{y} hsv:{img_hsv[y,x]} detect:{rect}")


def get_reference_rect(img):
    rect = np.zeros((4,), np.int32)
    fig = plt.figure()
    ax = fig.add_subplot(111)
    ax.imshow(img)
    cid = fig.canvas.mpl_connect(
        'button_press_event', lambda e: detect_rect(fig, ax, img, e, rect))
    plt.title(f"select ref")
    plt.show()
    return rect


# テンプレート画像の読み込み
img_file = f"{config.get('img', 'src')}/{code}.png"
img = cv2.cvtColor(cv2.imread(img_file), cv2.COLOR_BGR2RGB)

# zoom-level推定のためreferenceオブジェクトの範囲を検出
template_ref_rect = get_reference_rect(img)
template_ref_s = template_ref_rect[2] * template_ref_rect[3]
print(f"img ref: {template_ref_rect}")
map_ref_rect = get_reference_rect(map)
map_ref_s = map_ref_rect[2] * map_ref_rect[3]
print(f"map ref: {map_ref_rect}")
estimated_zoom = zoom + math.log2(template_ref_s/map_ref_s) * 0.5
estimated_zoom = round(estimated_zoom * 100)/100
print(f"img zoom(estimated): {estimated_zoom}")

# templateのクリップ
img = img[clip_y:(clip_y+clip_height), clip_x:(clip_x+clip_width), :]
template_ref_x = template_ref_rect[0] - clip_x
template_ref_y = template_ref_rect[1] - clip_y
# テンプレート画像中のピン指し示す位置の検出
pin = cv2.cvtColor(cv2.imread(config.get('img', 'pin')), cv2.COLOR_BGR2RGB)
res = cv2.matchTemplate(img, pin, cv2.TM_CCOEFF)
min_val, max_val, min_loc, max_loc = cv2.minMaxLoc(res)
pin_x += max_loc[0]
pin_y += max_loc[1]
print(f"pin x:{pin_x} y:{pin_y}")

# map画像のクリップ referenceオブジェクトのマッチング結果からおおよその範囲で絞る
ref2pin_x = pin_x - template_ref_x
ref2pin_y = pin_y - template_ref_y
scale = math.pow(2, zoom - estimated_zoom)
ref2pin_x *= scale
ref2pin_y *= scale
pin_map_x = map_ref_rect[0] + ref2pin_x
pin_map_y = map_ref_rect[1] + ref2pin_y
scale *= 1.5  # add margin
h, w, _ = map.shape
top = max(round(pin_map_y - pin_y * scale), 0)
bottom = min(round(pin_map_y + (clip_height - pin_y) * scale), h)
left = max(round(pin_map_x - pin_x * scale), 0)
right = min(round(pin_map_x + (clip_width - pin_x) * scale), w)

map = map[top:bottom, left:right, :]
map_x -= left
map_y -= top

# エッジ検出
img = cv2.Canny(img, 10, 50)
map = cv2.Canny(map, 10, 50)

# マップ画像どうしのテンプレートマッチング
z_range = np.linspace(
    estimated_zoom - 0.1,
    estimated_zoom + 0.1,
    21
)
result = []
for z in z_range:
    scale = math.pow(2, z - zoom)
    h, w = map.shape
    h = int(h * scale)
    w = int(w * scale)
    map_tmp = cv2.resize(map, dsize=(w, h))
    res = cv2.matchTemplate(map_tmp, img, cv2.TM_CCOEFF_NORMED)
    min_val, max_val, min_loc, max_loc = cv2.minMaxLoc(res)
    result.append((z, max_val, max_loc,))
    print(f"test z:{z}, val:{max_val} loc:{max_loc}")

max_arg = max(result, key=lambda x: x[1])
target_zoom, max_val, max_loc = max_arg
print(f"result z:{target_zoom}, val:{max_val}")

scale = math.pow(2, target_zoom - zoom)
h, w = map.shape
h = int(h * scale)
w = int(w * scale)
map_x *= scale
map_y *= scale
map = cv2.resize(map, dsize=(w, h))
map = cv2.Canny(map, 50, 100)

top_left = max_loc
bottom_right = (top_left[0] + clip_width, top_left[1] + clip_height)
extract = map.copy()[top_left[1]:bottom_right[1], top_left[0]:bottom_right[0]]
cv2.rectangle(map, top_left, bottom_right, 255, 10)

x = pin_x + top_left[0]
y = pin_y + top_left[1]

'''
経度（緯線）方向に関するデバイスpixel単位あたりの経度
dθ/dx = 1/R (const.)より緯度に依らず単純な比例関係で計算できる
経度±180[deg]がpixel coordinate の値域[0,256*2^target_zoom]に対応する
ただし pixel coordinate はDOMにおけるサイズのdip単位'px'に対応するから
画像上のピクセル単位に合わせる必要がある
'''
unit = 360 / (256 * math.pow(2, target_zoom)) / \
    float(config.get('map', 'density'))

lng = center_lng + (x - map_x) * unit
lat = center_lat - (y - map_y) * unit * math.cos(center_lat / 180 * math.pi)

print('code:%d lat:%.6f lng:%.6f' % (code, lat, lng))
pyperclip.copy('%.6f,%.6f' % (lat, lng))

f = open('log.txt', encoding='utf-8', mode='a')
f.write('%s code:%d lat:%.6f lng:%.6f\n' %
        (datetime.datetime.now(), code, lat, lng))
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
