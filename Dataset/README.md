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

### 


