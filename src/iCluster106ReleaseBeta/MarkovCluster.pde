// Markov Clustering implemented by Daniel Marshall

import org.math.array.*;
import org.math.array.LinearAlgebra.*;
import org.math.array.StatisticSample.*;
import org.math.array.util.*;
import org.math.array.DoubleArray.*;

import java.lang.*;
import java.util.ArrayList;
import java.io.*;

class MarkovCluster {

	int matrix_size;

	double[][] result;
	
	ArrayList clusters;

	int inflation;
	double expansion;
	
	private boolean is_not_zero(double[][] test_matrix) {	
	
		for(int i = 0; i < matrix_size; i++) {
			for(int j = 0; j < matrix_size; j++) {
				if (test_matrix[i][j] != 0.0) {
					return true;
				}		
			}
		}

		return false;
	}

	private void invert_elements() {

		for(int i = 0; i < matrix_size; i++) {
			for(int j = 0; j < matrix_size; j++) {
				if (result[i][j] != 0.0) {
					// avoiding 1/(less than 1)
					result[i][j] = 1 / (1 + result[i][j]);
				} else {
					result[i][j] = 1.0;
				}
			}
		}

	}

	private void calculate_result_matrix() {
  
                // main algorithm.
                // Perform markov clustering and with the final matrix stored in result
                
                 // assuming old_result initialised to zero on creation
                 // TODO: make sure it is zeroed
                double[][] old_result = new double[matrix_size][matrix_size];
  
                double col_count;
		int i = 0;

		while((is_not_zero(LinearAlgebra.minus(old_result, result))) && (i < 100))  {
			
			i++;

			old_result = DoubleArray.copy(result);

			// raise matrix several times

			for(int j = 0; j < (inflation - 1); j++) {

				result = LinearAlgebra.times(result, old_result);

			} 

			// elementwise power

			result = LinearAlgebra.raise(result, expansion);

			// sum and divide

			for(int j = 0; j < matrix_size; j++) {

				col_count = 0.0;

				// sum elements in column

				for(int k = 0; k < matrix_size; k++) {
					col_count = col_count + result[k][j];
				}

				for(int k = 0; k < matrix_size; k++) {
					result[k][j] = result[k][j] / col_count;
				}
			}

		}	
  
  	
	}

	private void build_cluster_list() {
            
          // Interprets the result matrix and build an ArrayList of ArrayList of indexes
          // for the clusters.
  
          boolean row_non_zero;

		// return a list of lists of indices
		// TODO: deal with entry not 1.0 case properly		

		for(int j = 0; j < matrix_size; j++) {

			row_non_zero = false;

			ArrayList current_cluster = new ArrayList();

			for(int k = 0; k < matrix_size; k++) {

				if (row_non_zero) {				
					if (result[j][k] > 0.0) {
  
						current_cluster.add(k);
					}
				} else {
					if (result[j][k] > 0.0) {
						row_non_zero = true;
						current_cluster.add(k);			
					}
				}
			}

			if (row_non_zero) {
				clusters.add(current_cluster);
			}			
		}		
	}

	public ArrayList getClusters() {

		// main computation function

		invert_elements();
                calculate_result_matrix();
		build_cluster_list();
		
		return clusters;

	}

	MarkovCluster(double[][] distance_matrix, int inflation, double expansion) {

		// TODO: error checking
		// 1. matrix must be square
		// 2. parameters can't be negative and other restrictions

		matrix_size = distance_matrix.length;
		this.inflation = inflation;
		this.expansion = expansion;

                // make sure we are working on a local copy of the matrix as we overwrite it
		result = DoubleArray.copy(distance_matrix);

		clusters = new ArrayList();

	}


}
