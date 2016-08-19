
#  Code to find treetops from a raster surface created from LiDAR point cloud. 
#  If necessary, this raster can be created using r.in.lidar command in GRASS
#  inputs: 
#  	- M: name of input raster map
#  	- THRESH (int): Treetop threshold. 

#  algorithm: Treetops are found by first determining local maxima
# 			(points with zero accumulation) on the original raster map. Call these points potential trees. 
# 			The map of local maxima is then inverted (multiplication by -1). Accumulation is computed 
# 			on the inverted map, and the actual trees are determined amongst the population of potential 
# 			trees by filtering the population of potential trees by an accumulation threshold. The threshold 
# 			is determined as the $THRESH percentile of the potential tree accumulation frequency distribution.

# todo: Could improve by buffering actual tree points to merge points that are too close. 

 # how to run: Navigate to script folder in GRASS terminal, run as 'sh find_trees.sh map_name_here threshold_integer_here'. 
 #	 		Recommend using something between 95-99 for the percentile threshold. 

# output: in script directory, points.kml corresponding to actual trees. 


M=$1
THRESH=$2

g.region -p -a raster=$M

r.mapcalc --overwrite "neg_dem = -1*$M"  
r.flow --overwrite elevation=neg_dem flowline=flowline flowlength=flowlength flowaccumulation=flowaccumulation
r.flow --overwrite elevation=$M flowline=flowline_normal flowlength=flowlength_normal flowaccumulation=flowaccumulation_normal
r.mapcalc "potential_trees = if(flowaccumulation_normal==0,flowaccumulation,0)"
r.null --overwrite map=potential_trees setnull=0
r.quantile input=potential_trees percentiles=$THRESH > quant.txt
value=$(<quant.txt)
value_spaces=$(echo $value | tr ":" " ")
arr=($value_spaces)
per=${arr[2]}
rm quant.txt
r.mapcalc --overwrite "tree_zones = (potential_trees>$per)"
r.null --overwrite map=tree_zones setnull=0
r.clump --overwrite -d tree_zones out=tree_zones_clumped
r.mapcalc --overwrite "zeros = neg_dem*0"    
r.volume --overwrite input=zeros clump=tree_zones_clumped centroids=centr_points
v.build map=centr_points
v.out.ogr input=centr_points output=points.kml type=point format=KML