# Preparing the dataset.

---

### Download and create the environment

* Create a conda environment from `environment.yml` for the conversion script.

```
conda env create --file environment.yml
```

* Run the setup script setup.py in the same conda environment in order to install the `deepdrive_dataset` package modified from original deepdrive_dataset package which can be found [here](https://github.com/meyerjo/deepdrive_dataset_tfrecord)

```
python setup.py install
```

* Download the BDD100k dataset from http://bdd-data.berkeley.edu/login.html and place it in the repository

---

### Prepare the dataset and conversion script

* Unzip the downloaded images into `bdd100k/images/100k/{val, train, test}` and the labels to `bdd100k/labels/bdd100k_labels_images_train.json`.

---

###  Generating the dataset.

Run `create_tfrecord.py` with the following flags:

> `python create_tfrecord.py --fold_type train --version 100k --elements_per_tfrecord 1000000` 

> `python create_tfrecord.py --fold_type train --version 100k --elements_per_tfrecord 1000000` 

This will create two folders within `/bdd100k/tfrecord/100k/{train, val}` containing `output_val100k__000000.tfrecord` which can be copied to the training location.

As a sanity check you may run checkhere.ipynb which will output the bytestream of a single instance within the `tfrecord` file.

###  Acknowledgements

The [original scripts](https://github.com/meyerjo/deepdrive_dataset_tfrecord) were converted to the desired tensorflow COCO model format. The bounding boxes were normalized with respect to the center i.e `+-0.4 xoffset` rather than pixel level corner coordinates. The labels were collated into a single JSON format.  
