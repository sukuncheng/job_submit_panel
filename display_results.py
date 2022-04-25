import os
import matplotlib as plt

dirs = [
        '/cluster/work/users/chengsukun/plotting/ensmean_freerun',
        '/cluster/home/chengsukun/src/yumeng_workpath/plotting/ensmean_FreeRun_OceanNudgingDd5'
        ]
sub_dir = 'maps_bias'
obs_source= ("OsisafConc", "Cs2SmosThick")

fig = plt.figure(1, figsize = (5, 5))
for src in obs_source:
    plt.clf()
    for dir in dirs:
        file_list = os.path.join(dir,src,sub_dir)  # find all files *.png in this path
        
    
    fig_dir = './plotting'
    os.makedirs(fig_dir, exist_ok=True)
    figfile = os.path.join(fig_dir, f'Comparison_{src}.png')
    plt.savefig(figfile)