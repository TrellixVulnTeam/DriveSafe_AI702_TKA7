# Preparing the dataset.

---

### Download and create the environment

Create a conda environment from `environment.yml` for the conversion script.

```
conda env create --file environment.yml
```

* Download the BDD100k dataset from http://bdd-data.berkeley.edu/login.html

---

### Prepare the dataset and conversion script

* Unzip the downloaded images into `bdd100k/images/100k/{val, train, test}` and the labels to `bdd100k/labels/bdd100k_labels_images_train.json`.