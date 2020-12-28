                    //perturbation is called in  time-dependant elements
                    if (tcc or precip)
                        bool do_perturbation_elements=true;
                    
                    // load perturbation from file 
                    if (M_comm.rank() == 0) {                          
                        std::string filename_root = "synforc_elements.nc";  // 
                        ifstream iofile(filename_root.c_str());
                        LOG(DEBUG) << "### existence of "<< filename_root<<", 1-yes, 0-no: " <<  iofile.good()  << "\n";
                        if ( iofile.good() ) {
                            netCDF::NcFile dataFile(filename_root, netCDF::NcFile::read);
                            netCDF::NcVar data;
                            if (tcc??)
                            {
                                data = dataFile.getVar("tcc_previous");
                                data.getVar(&M_dataset->synwind_previous[0]);
                                data = dataFile.getVar("tcc_current");
                                data.getVar(&M_dataset->synwind_current[0]);
                            }
                            else if(precip??)
                            {
                                data = dataFile.getVar("precip_previous");
                                data.getVar(&M_dataset->synwind_previous[0]);
                                data = dataFile.getVar("precip_current");
                                data.getVar(&M_dataset->synwind_current[0]);
                            }
                        }
                    }
                        // where is the previous wind field used? Is it necessary to broadcast and add previous perturbation to previous wind field
                        M_comm.barrier(); 
                        LOG(DEBUG) << "### Broadcast previous perturbations loaded from restart file to all processors\n"; 
                        if (previous_perturbation_exist==1 && do_perturbation_elements){
                             
                            boost::mpi::broadcast(M_comm, &M_dataset->synforc[0], M_dataset->synforc.size(), 0); 
                            // no need to broadcast previous randfld, which is only used in root processor for generating current perturbation.  
                        }
                    }

                    if (do_perturbation_elements)
                    {
                        LOG(DEBUG) << "### Add perturbations to previous wind fields loaded from wind dataset\n";  
                        // where is the previous wind field used? If it is not used, then it is no need to broadcast and add previous perturbation to previous wind field
                        // indexes defined in ec2_elements, asr2_elements
                        perturbation.addPerturbation(M_dataset->variables[5].loaded_data[0], M_dataset->synforc, M_full,N_full, x_start, y_start, x_count, y_count, 3); //tcc, i in variables[i]  defined in dataset.cpp
                        perturbation.addPerturbation(M_dataset->variables[6].loaded_data[0], M_dataset->synforc, M_full,N_full, x_start, y_start, x_count, y_count, 4); //precip, last parameter defined in save_randfld_synforc() in mod_random_forcing.f90
                    }

                    LOG(DEBUG) << "### Generate current perturbations based on randfld at previous time\n"; 
                    if (M_comm.rank() == 0) {      
                        perturbation.synopticPerturbation(M_dataset->synforc, M_dataset->randfld, M_full, N_full, previous_perturbation_exist);
                    }

                    LOG(DEBUG) << "### Broadcast perturbations\n";  
                    M_comm.barrier();
                    boost::mpi::broadcast(M_comm, &M_dataset->synforc[0], M_dataset->synforc.size(), 0); 
                    // if (M_comm.rank() == 10) {  
                    //     for(int i = 0; i < MN_full; i++)
                    //        std::cout<<"x1  "<< i<< ",  "<<M_dataset->synforc[i]<<", "<<M_dataset->synforc[MN_full+i]<<"\n";  
                    // }
                     //save prevous wind speed to temporal file 
                    filename_root = "synwind_node.nc";
                    netCDF::NcFile dataFile(filename_root, netCDF::NcFile::add@@@@@@);
                    netCDF::NcDim dim_synforc = dataFile.addDim("synwind_current",2*MN_full) 
                    netCDF::NcVar data=dataFile.addVar("synwind_current",netCDF::ncFloat, dim_synforc);
                    data.putVar(&dataset->synforc[0],2*MN_full);
                    if (do_perturbation_elements)
                    {
                        LOG(DEBUG) << "### Add perturbations to current wind fields\n";  
                        M_comm.barrier();      
                        perturbation.addPerturbation(M_dataset->variables[5].loaded_data[1], M_dataset->synforc, M_full,N_full, x_start, y_start, x_count, y_count, 3); //tcc defined in dataset.cpp
                        perturbation.addPerturbation(M_dataset->variables[6].loaded_data[1], M_dataset->synforc, M_full,N_full, x_start, y_start, x_count, y_count, 4); //precip
                    }