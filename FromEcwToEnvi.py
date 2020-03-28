#打开Arcgis的IDLE工具
#使用CopyRaster_management模块，将其他栅格数据统一转换成envi格式的数据。
import arcpy
import os
arcpy.env.pyramid = "NONE"
arcpy.env.workspace = r"C:/Temp/2018"
print 'start'
for file in os.listdir("C:/Temp/2018"):
    if file.endswith(".ecw"):
        print file 
        input=file
        newFile=file.split('.ecw')[0]+".dat"
        print newFile
        output=newFile
        arcpy.CopyRaster_management (input,output,format="ENVI")
print 'end'
