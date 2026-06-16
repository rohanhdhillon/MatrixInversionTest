import numpy as numpy
import matplotlib.pyplot as plt
import numpy as np
import glob

FileNames = np.array(glob.glob("RohanResults/fort.*"))
FileArrangeIndex = np.array([int(FileItem.split(".")[-1]) for FileItem in FileNames])
FileNames = FileNames[np.argsort(FileArrangeIndex)]
XPlot = np.linspace(1000,15000,100)
YPlot = 1e-10*XPlot**3
plt.figure(figsize=(12,8))
for FileCounter,FileItem in enumerate(FileNames):
    Data = np.loadtxt(FileItem)
    NCores = int(FileItem.split(".")[-1])
    print("The shape of data is:", NCores)

    if FileCounter==0:
        LW= "-"
        
    elif FileCounter==1:
        LW= ":"
    elif FileCounter==2:
        LW= "--"
    elif FileCounter==3:
        LW= "-."
    elif FileCounter==4:
        LW= (0,(1,10))
        LW= (5,(10,3))
    
    plt.plot(Data[:,0], Data[:,1]*NCores, marker="+", markersize=8, color="red", linestyle=LW, label=str(NCores)+" dgetri ")
    plt.plot(Data[:,0], Data[:,2]*NCores, color="blue", marker="x", markersize=5, linestyle=LW, label=str(NCores)+" MatInv ")
    plt.plot(Data[:,0], Data[:,3]*NCores, marker="d", markersize=5, color="green", linestyle=LW, label=str(NCores)+" dsystri ")
    plt.plot(Data[:,0], Data[:,4]*NCores, color="brown", marker="p", markersize=5, linestyle=LW, label=str(NCores)+" Cholesky")

#plt.plot(XPlot, YPlot, "k-", lw=4, alpha=0.5, label="x=y^3 graph")
plt.xlabel("Matrix Dimension", fontsize=25)
plt.ylabel("Total Time Taken x Number of Cores [s]", fontsize=25)
plt.legend(ncol=4, fontsize=15)
#plt.legend(ncols=2)
plt.xscale('log')
plt.yscale('log')
plt.grid(True)
plt.savefig("PerformanceGraph.png")
plt.close()
