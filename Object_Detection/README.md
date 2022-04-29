## Training a Custom Object Detector
Please refer to the `TF2_Object_Detection.ipynb` notebook for step-by-step instructions for installation of `TF2 Object Detection API` and training of the Custom model. The references for creating the following notebook are listed below.

The `inference_demo.py` can be used to run inference of our model. To run the demo script please follow the instructions given in `TF2_Object_Detection.ipynb` and complete the installation of the `Object detection API`. An example inference output is given as `output.jpg`

After the training process the model is converted into `tflite` format using `Post-Training Quantization`.

## References
* [TF2 Object Detection](https://github.com/tensorflow/models/tree/master/research/object_detection)
* [TF2 Object Detection API Tutorial](https://tensorflow-object-detection-api-tutorial.readthedocs.io/en/latest/training.html)
* [TF2 Model Zoo](https://github.com/tensorflow/models/blob/master/research/object_detection/g3doc/tf2_detection_zoo.md)
* [Post-Training Quantization](https://www.tensorflow.org/lite/performance/post_training_quantization )
