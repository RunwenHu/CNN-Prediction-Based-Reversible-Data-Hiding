import os
import cv2
import math
import torch
import utils
import matlab
import argparse
import matlab.engine
import numpy as np
from model.predict_model import PredictModel


def PsnrC(img1, img2):
    # calculate the PSNR
    img1 = np.array(img1, dtype=np.float)
    img2 = np.array(img2, dtype=np.float)
    mse = np.mean((img1 - img2) ** 2)
    if mse < 1.0e-10:
        return 100
    return 10 * math.log10(255.0 ** 2 / mse)


def main():
    engine = matlab.engine.start_matlab()  # Start MATLAB process

    parser = argparse.ArgumentParser(description='Calculating PSNR')
    parser.add_argument('--img-size', '-size',  nargs='+', default=[512, 512], type=int,
                        help='The size of the images.')

    parser.add_argument('--model-pth', '-model', default=r'.\model_parameter\model_state.pth', type=str,
                        help='The place of the model parameter.')

    parser.add_argument('--img-path', '-folder', default=r'.\standard_test_images', type=str,
                        help='The place of the image to be predicted.')

    parser.add_argument('--mode', '-mode', default='histogram_shifting', type=str,
                        help='The embedding ways.')

    parser.add_argument('--watermark-length', '-length', default=10000, type=int,
                        help='The length of the watermark.')

    args = parser.parse_args()

    message_to_embed = np.random.randint(0, 2, [args.watermark_length])
    img_size = tuple(args.img_size)
    img_path = args.img_path
    img_file_list = os.listdir(img_path)

    psnr1 = []

    device = torch.device('cuda') if torch.cuda.is_available() else torch.device('cpu')
    model = PredictModel(device)

    utils.load_model(args.model_pth, model)

    for i in range(0, len(img_file_list)):
        print(i)

        img_file = os.path.join(img_path, img_file_list[i])
        img = cv2.imread(img_file)
        img_resize = cv2.resize(img, img_size, interpolation=cv2.INTER_CUBIC)
        img_gray = cv2.cvtColor(img_resize, cv2.COLOR_BGR2GRAY)
        img_gray = np.array(img_gray, dtype=np.float)#Convert input image to gray image with size of 512*512
        if args.mode == 'histogram_shifting':
            #histogram shifting
            img_gray_embed = utils.cnn_histogram_shifting(img_gray, message_to_embed, device, model, engine)
        elif args.mode == 'expansion_embedding':
            #expansion embedding
            img_gray_embed = utils.cnn_expansion(img_gray, message_to_embed, device, model, engine)

        psnr1.append(np.round(PsnrC(img_gray_embed, img_gray), 2))

    print('CNNP psnr = {}'.format(np.round(np.mean(psnr1), 2)))

    engine.exit()


if __name__ == "__main__":
    main()
