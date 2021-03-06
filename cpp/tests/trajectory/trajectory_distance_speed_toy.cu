/*
 * Copyright (c) 2019, NVIDIA CORPORATION.
 *
 * Licensed under the Apache License, Version 2.0 (the "License");
 * you may not use this file except in compliance with the License.
 * You may obtain a copy of the License at
 *
 *     http://www.apache.org/licenses/LICENSE-2.0
 *
 * Unless required by applicable law or agreed to in writing, software
 * distributed under the License is distributed on an "AS IS" BASIS,
 * WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
 * See the License for the specific language governing permissions and
 * limitations under the License.
 */

#include <time.h>
#include <sys/time.h>
#include <vector>
#include <string>
#include <iostream>

#include <gtest/gtest.h>
#include <thrust/device_vector.h>
#include <utilities/error_utils.hpp>
#include <cuspatial/types.hpp> 
#include <cuspatial/trajectory.hpp> 
#include <utility/utility.hpp>
#include <utility/trajectory_thrust.cuh>

#include <tests/utilities/column_wrapper.cuh>
#include <tests/utilities/cudf_test_utils.cuh>
#include <tests/utilities/cudf_test_fixtures.h>

struct TrajectoryDeriveToy : public GdfTest 
{
};   
   
TEST_F(TrajectoryDeriveToy, trajectoryderivetest)
{
    //three sorted trajectories with 5,4,3 points, respectively
    std::cout<<"in TrajectoryDeriveToy"<<std::endl;
    //assuming x/y are in the unit of killometers (km); 
    //computed distance and speed are in the units of meters and m/s, respectively
    double point_x[]={1.0,2.0,3.0,5.0,7.0,1.0,2.0,3.0,6.0,0.0,3.0,6.0};
    double point_y[]={0.0,1.0,2.0,3.0,1.0,3.0,5.0,6.0,5.0,4.0,7.0,4.0};
    uint32_t traj_len[]={5,4,3};
    uint32_t traj_offset[]={5,9,12};

    //handling timestamps - use millsecond field only for now 
    int point_hh[]={0,1,2,3,4,0,1,2,3,0,1,2};
    int point_ms[]={1,2,3,4,5,1,2,3,4,1,2,3};
    int num_point=sizeof(point_x)/sizeof(double);
    int num_traj=sizeof(traj_len)/sizeof(uint32_t);
    std::cout<<"num_point="<<num_point<<"   num_traj="<<num_traj<<std::endl;

    std::vector<cuspatial::its_timestamp> point_ts;
    for(int i=0;i<num_point;i++)
    {
        cuspatial::its_timestamp ts;
        memset(&ts,0,sizeof(cuspatial::its_timestamp));
        ts.hh=point_hh[i];
        ts.ms=point_ms[i];	
        point_ts.push_back(ts);
    }

    cudf::test::column_wrapper<double> point_x_wrapp{std::vector<double>(point_x,point_x+num_point)};
    cudf::test::column_wrapper<double> point_y_wrapp{std::vector<double>(point_y,point_y+num_point)};
    cudf::test::column_wrapper<cuspatial::its_timestamp> point_ts_wrapp{point_ts};
    cudf::test::column_wrapper<uint32_t> traj_len_wrapp{std::vector<uint32_t>(traj_len,traj_len+num_traj)};
    cudf::test::column_wrapper<uint32_t> traj_pos_wrapp{std::vector<uint32_t>(traj_offset,traj_offset+num_traj)};

    std::cout<<"calling cuspatial::trajectory_distance_and_speed"<<std::endl;
    std::pair<gdf_column,gdf_column> dist_speed_pair=
    cuspatial::trajectory_distance_and_speed(*(point_x_wrapp.get()),*(point_y_wrapp.get()),
    *(point_ts_wrapp.get()),*(traj_len_wrapp.get()),*(traj_pos_wrapp.get()));

    CUDF_EXPECTS(num_traj==dist_speed_pair.first.size && num_traj==dist_speed_pair.second.size,
        "size of output dist/speed columns should be the same as the number of the input trajectories");

    std::cout<<"computed distance/speed"<<std::endl;
    int num_print = (num_traj<10)?num_traj:10;  
    thrust::device_ptr<double> traj_distance_ptr=
        thrust::device_pointer_cast(static_cast<double*>(dist_speed_pair.first.data));
    thrust::device_ptr<double> traj_speed_ptr=
        thrust::device_pointer_cast(static_cast<double*>(dist_speed_pair.second.data));

    std::cout<<"computed distance (in meters):"<<std::endl;
    thrust::copy(traj_distance_ptr,traj_distance_ptr+num_print,std::ostream_iterator<double>(std::cout, " "));std::cout<<std::endl; 
    std::cout<<"computed speed (in m/s):"<<std::endl;
    thrust::copy(traj_speed_ptr,traj_speed_ptr+num_print,std::ostream_iterator<double>(std::cout, " "));std::cout<<std::endl; 
}
