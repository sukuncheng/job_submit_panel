sudo -s
docker build . -t nextsim_enkf_ec2

# enkf docker
docker run -it --rm -v /root/Desktop/nextsim_1st_case_Ali/output/filter:/docker_io nextsim_enkf
        
docker run -it --rm --security-opt seccomp=unconfined \
                -v /home/cheng/Desktop/data:/data \
                -v /home/cheng/Desktop/test1_201811/one_step_nextsim_enkf/filter:/docker_io \
                nextsim_enkf 
cp /nextsim/modules/enkf/enkf-c/bin/enkf_* . &&  make enkf > enkf.out
rm observations*.nc

# nextsim docker
docker run -it  \
        --security-opt seccomp=unconfined \
        -v /home/cheng/Desktop/data:/data \
        -v /home/cheng/Desktop/mesh:/mesh \
        -v /home/cheng/Desktop/test1_201811/one_step_nextsim_enkf:/docker_io \
        nextsim_enkf 
        
mpirun --allow-run-as-root -np 2 nextsim.exec -use_coords -mat_mumps_icntl_23 1600 \
--config-files=/docker_io/nextsim.cfg  &> debug.log  

valgrind --trace-children=yes -v --demangle=yes --gen-suppressions=all mpirun --allow-run-as-root -np 2 nextsim.exec -use_coords -mat_mumps_icntl_23 600 --config-files=/docker_io/nextsim.cfg  &> debug.log



##vector for saving large array in c++
https://blog.csdn.net/u014453443/article/details/98057251?utm_medium=distribute.pc_relevant.none-task-blog-BlogCommendFromMachineLearnPai2-1.nonecase&depth_1-utm_source=distribute.pc_relevant.none-task-blog-BlogCommendFromMachineLearnPai2-1.nonecase
vector<vector<int>> v(r, vector<int>(c, 0));
vector<vector<int>> v;
v.resize(r); // row
for (int i = 0; i < r; ++i){
    v[i].resize(c); // column
}
printf("%d\n",ranstep);
 vector<vector<int>> vec(10, vector<int>(8)); //10行8列，全部初始化为零
vec.size()是行数
vec[0].size()是列数
cout << vec[i][n] << " ";


git config --global credential.helper store



杀死所有running状态的容器
docker kill $(docker ps -q)

删除所有已经停止的容器
docker rm $(docker ps -a -q)

删除所有'untagged/dangling' ()状态的镜像
docker rmi $(docker images -q -f dangling=true)

删除 none 镜像
docker rmi $(docker images -a|grep "<none>"|awk '$1=="<none>" {print $3}')

删除所有镜像：
docker rmi $(docker images -q)
# 
docker run --rm -d \   -d 后台运行, --rm 结束后删除容器， > ./log.txt 2>&1 保存日志
        --security-opt seccomp=unconfined \
        -v $ROOT_DIR/data:/data \
        -v $ROOT_DIR/mesh:/mesh \
        -v $MEMPATH:/docker_io \
        $docker_image \
        sh -c "cd /docker_io && \
        mpirun --allow-run-as-root -np $NPROC nextsim.exec \
        -mat_mumps_icntl_23 1000 \
        --config-files=/docker_io/nextsim.cfg > ./log.txt 2>&1 " 
        