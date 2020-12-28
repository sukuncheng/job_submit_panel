                    bool do_perturbation_nodes=true;    
                    int  previous_perturbation_exist=1;
                    //For the 1st perturbation of the simulation
                    if (M_dataset->synforc.size()==0){ 
                    //initialize dimensional/nondimensional perturbation fields as 0.
                    // sizes are consistent with mod_random_forcing.f90:save_randfld_synforc()
                        M_dataset->randfld.resize(10*MN_full,0.); 
                        M_dataset->synforc.resize(4*MN_full,0.); 
                        M_dataset->synwind_uv.resize(2*MN_full,0.); 

                        // load perturbation from 'restart' file 
                        if (M_comm.rank() == 0) {                          
                            std::string filename_root = "WindPerturbation_mem" + std::to_string(M_comm.rank()+1) +".nc";  // 
                            ifstream iofile(filename_root.c_str());
                            LOG(DEBUG) << "### existence of "<< filename_root<<", 1-yes, 0-no: " <<  iofile.good()  << "\n";
                            previous_perturbation_exist = iofile.good();
                            if ( iofile.good() ) {
                                netCDF::NcFile dataFile(filename_root, netCDF::NcFile::read);
                                netCDF::NcVar data;
                                data = dataFile.getVar("randfld"); 
                                data.getVar(&M_dataset->randfld[0]);
                                data = dataFile.getVar("synforc");
                                data.getVar(&M_dataset->synforc[0]);
                                data = dataFile.getVar("synforc");
                                data.getVar(&M_dataset->synforc[0],M_dataset->synforc.size()); 
                            }
                            //save prevous wind speed to a temporal file 
                            filename_root = "synforc_elements.nc";
                            netCDF::NcFile dataFile(filename_root, netCDF::NcFile::replace);
                            netCDF::NcDim dim = dataFile.addDim("x",MN_full) 
                            netCDF::NcVar data;
                            data = dataFile.addVar("tcc_previous",netCDF::ncFloat, dim);
                            data.putVar(&dataset->synforc[2*MN_full],MN_full);                    
                            data = dataFile.addVar("precipitation_previous",netCDF::ncFloat, dim);
                            data.putVar(&dataset->synforc[2*MN_full],MN_full);
                        }        
                              
                    
                    // where is the previous wind field used? Is it necessary to broadcast and add previous perturbation to previous wind field
                    M_comm.barrier();
                    LOG(DEBUG) << "### Broadcast perturbations\n";  
                    boost::mpi::broadcast(M_comm, &M_dataset->synwind_previous[0], M_dataset->synwind_previous.size(), 0); 
                    boost::mpi::broadcast(M_comm, &M_dataset->synwind_current[0], M_dataset->synwind_current.size(), 0); 

                    LOG(DEBUG) << "### Add perturbations to wind fields\n";  

                    // previous field
                    perturbation.addPerturbation(M_dataset->variables[0].loaded_data[0], M_dataset->synforc, M_full,N_full, x_start, y_start, x_count, y_count, 1); 
                    perturbation.addPerturbation(M_dataset->variables[1].loaded_data[0], M_dataset->synforc, M_full,N_full, x_start, y_start, x_count, y_count, 2); 

                    // current field                        
                    perturbation.addPerturbation(M_dataset->variables[0].loaded_data[1], M_dataset->synforc, M_full,N_full, x_start, y_start, x_count, y_count, 1); 
                    perturbation.addPerturbation(M_dataset->variables[1].loaded_data[1], M_dataset->synforc, M_full,N_full, x_start, y_start, x_count, y_count, 2); 
                    // double M_min=*std::min_element(M_dataset->variables[0].loaded_data[0].begin(),M_dataset->variables[0].loaded_data[0].end());
                    // double M_max=*std::max_element(M_dataset->variables[0].loaded_data[0].begin(),M_dataset->variables[0].loaded_data[0].end());
                    // LOG(DEBUG) << "### MINMAX: " << M_min << " - " << M_max << "\n";
