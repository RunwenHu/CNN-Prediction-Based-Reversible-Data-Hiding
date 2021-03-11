import torch
from model.cnnp import CNNP

# construct the predict model, which is used to predict the image
class PredictModel:
    def __init__(self, device):
        super(PredictModel, self).__init__()
        self.model = CNNP().to(device)

    def test_on_batch(self, input_image):
        self.model.eval()
        with torch.no_grad():
            predicted_image = self.model(input_image)
        return predicted_image











