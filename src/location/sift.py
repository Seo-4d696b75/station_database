import cv2

template = cv2.imread('raw/100201.png')
template = template[800:1400, 0:1080, :]
template = cv2.Canny(template, 10, 50)

reference = cv2.imread('map/100201.h.png')
h, w, _ = reference.shape
reference = reference[238:(h-60), 0:(w-50), :]
reference = cv2.Canny(reference, 10, 50)

sift = cv2.SIFT_create()
keypoints_template, descriptors_template = sift.detectAndCompute(
    template, None)
img_sift = cv2.drawKeypoints(template, keypoints_template, None, flags=4)
cv2.imwrite("sift_template.jpg", img_sift)
keypoints_reference, descriptors_reference = sift.detectAndCompute(
    reference, None)
img_sift = cv2.drawKeypoints(reference, keypoints_reference, None, flags=4)
cv2.imwrite("sift_reference.jpg", img_sift)

bf = cv2.BFMatcher()
matches = bf.match(descriptors_template, descriptors_reference)
matches = sorted(matches, key = lambda x:x.distance)[:10]

matches_img = cv2.drawMatches(
    template,
    keypoints_template,
    reference,
    keypoints_reference,
    matches,
    None,
    flags=2)
cv2.imwrite('matches.jpg', matches_img)
