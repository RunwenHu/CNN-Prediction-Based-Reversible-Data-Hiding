import cv2
import torch
import matlab
import numpy as np
from torchvision import transforms
from model.predict_model import PredictModel


def load_model(file_name, model: PredictModel):
    checkpoint = torch.load(file_name)
    model.model.load_state_dict(checkpoint['network'])


def parse_sample(img_gray, num=0):

    source = np.zeros(img_gray.shape)
    for i in range(1, img_gray.shape[0] - 1):
        for j in range(1, img_gray.shape[1] - 1):
            if (i + j) % 2 == num:
                source[i - 1, j] = img_gray[i - 1, j]
                source[i + 1, j] = img_gray[i + 1, j]
                source[i, j - 1] = img_gray[i, j - 1]
                source[i, j + 1] = img_gray[i, j + 1]
    if num == 1:
        source = cv2.rotate(source, rotateCode=cv2.ROTATE_90_CLOCKWISE)
    source = np.expand_dims(source, axis=2)
    return source


def cnn_histogram_shifting(img_gray, message_to_embed, device, model, engine):
    half_message = np.int32(len(message_to_embed) / 2)
    for i in range(0, 2):
        num = i
        message_to_embed_half = message_to_embed[i * half_message:(i + 1) * half_message]
        input_image = parse_sample(img_gray, num=num)
        input_image = transforms.ToTensor()(input_image)
        input_image = input_image.unsqueeze(1)
        input_image = input_image.type(torch.FloatTensor).to(device)
        predicted_image = model.test_on_batch(input_image)
        predicted_image = predicted_image.squeeze(1).squeeze(0)

        predicted_image = predicted_image.cpu().numpy()
        predicted_image = np.around(predicted_image)

        if num == 1:
            predicted_image = cv2.rotate(predicted_image, rotateCode=cv2.ROTATE_90_COUNTERCLOCKWISE)

        predicted_image_new = np.zeros(img_gray.shape)
        predicted_image_new[1:img_gray.shape[0] - 1, 1:img_gray.shape[1] - 1] = predicted_image
        img_w = engine.cnn_histogram_shifting(matlab.double(img_gray.tolist()),
                                              matlab.double(predicted_image_new.tolist()),
                                              matlab.double(message_to_embed_half.tolist()), num)
        img_w = np.array(img_w, dtype=np.float)
        img_gray = img_w

    return img_gray


def cnn_expansion(img_gray, message_to_embed, device, model, engine):
    half_message = np.int32(len(message_to_embed) / 2)
    for i in range(0, 2):
        num = i
        message_to_embed_half = message_to_embed[i * half_message:(i + 1) * half_message]
        input_image = parse_sample(img_gray, num=num)
        input_image = transforms.ToTensor()(input_image)
        input_image = input_image.unsqueeze(1)
        input_image = input_image.type(torch.FloatTensor).to(device)
        predicted_image = model.test_on_batch(input_image)
        predicted_image = predicted_image.squeeze(1).squeeze(0)

        predicted_image = predicted_image.cpu().numpy()
        predicted_image = np.around(predicted_image)

        if num == 1:
            predicted_image = cv2.rotate(predicted_image, rotateCode=cv2.ROTATE_90_COUNTERCLOCKWISE)

        predicted_image_new = np.zeros(img_gray.shape)
        predicted_image_new[1:img_gray.shape[0] - 1, 1:img_gray.shape[1] - 1] = predicted_image
        img_w = engine.cnn_expansion(matlab.double(img_gray.tolist()),
                                              matlab.double(predicted_image_new.tolist()),
                                              matlab.double(message_to_embed_half.tolist()), num)
        img_w = np.array(img_w, dtype=np.float)
        img_gray = img_w

    return img_gray





