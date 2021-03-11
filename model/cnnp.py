

# construct the proposed CNNP
import torch.nn as nn

class CNNP(nn.Module):
    def __init__(self):
        super(CNNP, self).__init__()
        channel = 32
        layers = [nn.Conv2d(1, channel, 3, 1, 0)]
        layers.append(nn.LeakyReLU(inplace=True))
        layers.append(nn.Conv2d(channel, channel, 3, 1, 1))
        self.conv1 = nn.Sequential(*layers)

        layers = [nn.Conv2d(1, channel, 5, 1, 1)]
        layers.append(nn.LeakyReLU(inplace=True))
        layers.append(nn.Conv2d(channel, channel, 3, 1, 1))
        self.conv2 = nn.Sequential(*layers)

        layers = [nn.Conv2d(1, channel, 7, 1, 2)]
        layers.append(nn.LeakyReLU(inplace=True))
        layers.append(nn.Conv2d(channel, channel, 3, 1, 1))
        self.conv3 = nn.Sequential(*layers)

        layers = [nn.Conv2d(channel, channel, 3, 1, 1)]
        layers.append(nn.LeakyReLU(inplace=True))
        layers.append(nn.Conv2d(channel, channel, 3, 1, 1))
        self.conv4 = nn.Sequential(*layers)

        layers = [nn.Conv2d(channel, channel, 3, 1, 1)]
        layers.append(nn.LeakyReLU(inplace=True))
        layers.append(nn.Conv2d(channel, 1, 3, 1, 1))
        self.conv5 = nn.Sequential(*layers)

    def forward(self, images):
        out1 = self.conv1(images)
        out2 = self.conv2(images)
        out3 = self.conv3(images)
        out4 = self.conv4(out1 + out2 + out3)
        out5 = self.conv5(out1 + out2 + out3 + out4)
        return out5
