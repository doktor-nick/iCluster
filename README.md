# iCluster

The core idea of iCluster is to spatially place images of fluorescent protein subcellular localisation is such a way that images that are similar are spatially close. It does this by generating threshold adjacency statistics for each image to associate a 27 dimensional vector of real numbers with each image. The set of points in 27 dimensional space is then Sammon mapped into 2 or 3 dimensions in such a
way as to preserve the distances between the points as well as is possible. Hence statistically similar images are spatially close in the visualisation. Statistical tests for difference between image sets may also be performed, statistically representative images found, along with a number of other features.

iCluster can also work with user supplied statistics for each image. It can also work without images to show the relationships between high dimensional sets of points.

The movie in the movie/ folder gives an idea of some of the features.

More description about iCluster can be found at the [web site](http://icluster.imb.uq.edu.au/).

and in the papers:

[Hamilton N., Wang J., Kerr M.C., Teasdale R.D. Statistical and visual differentiation of high throughput subcellular imaging. BMC Bioinformatics 2009;10:94.](http://bmcbioinformatics.biomedcentral.com/articles/10.1186/1471-2105-10-94)

[Hamilton N., Teasdale R.D. Visualizing and clustering high throughput sub-cellular localization imaging BMC Bioinformatics 2008;9:81.](http://bmcbioinformatics.biomedcentral.com/articles/10.1186/1471-2105-9-81)

WARNING: iCluster has not yet been updated to work with Processsing 3. Processing 2 is the preferred version to use. Getting iCluster to work in Processing 3 should be fairly straight forward, but I've just got to get around to it.
