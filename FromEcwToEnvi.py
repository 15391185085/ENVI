#��Arcgis��IDLE����
#ʹ��CopyRaster_managementģ�飬������դ������ͳһת����envi��ʽ�����ݡ�
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
