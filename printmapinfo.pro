PRO printMapInfo
  on_error, 2
  ;rfn="C:\Temp\"
  rfn=dialog_pickfile(/DIRECTORY,title='选择要读取的遥感目录')
  wfn=dialog_pickfile(title='选择要写入的CSV文件')
  
  rfn = STRMID(rfn, 0, rfn.Strlen()-1)

  print,rfn
  print,wfn
  e=ENVI(/CURRENT)
  list0=file_search(rfn,'*.tif',count=num)
  GET_LUN, lun
  openw,lun,wfn,/get
  printf,lun,'影像存储路径,影像名称,所属盟市,所属旗县,存储格式,分辨率,投影坐标系,左上经度,左上纬度,右下经度,右下纬度,影像拍摄时间（年月日）,数据类型'

  for i=0,num-1 do begin
    file=list0[i].ToString();
    subString = STRMID(file, rfn.Strlen(), file.Strlen()-rfn.Strlen())
    split1 = STRSPLIT(subString, '\', /PRESERVE_NULL, /EXTRACT)
    slist=split1.ToList()
    
    if (slist.LENGTH eq 4) then begin
      
      Raster = e.OpenRaster(file)
      a=printexc(split1[1],split1[2],split1[3],file,Raster)
      printf,lun,a

    endif

  endfor
  free_lun,lun

END

function printexc,city,county,filename,file,Raster
  str=""
  str=str+file+","
  str=str+filename+","
  str=str+city+","
  str=str+county+","
  str=str+"tif,"
  str=str+STRING(Raster.SPATIALREF.PIXEL_SIZE)+","
  spa=Raster.SPATIALREF.COORD_SYS_STR
  list=STRSPLIT(spa, '"', /PRESERVE_NULL, /EXTRACT)
  slist1=list.ToList()
  str=str+slist1[1]+","
  envi_open_file, file, r_fid=fid, /no_realize, /no_interactive_query
  if (fid eq -1) then return,0 ;check fid
  envi_file_query, fid, ns=ns, nl=nl, nb=nb
  pos = lindgen(nb);

  print,nl
  print,ns
  fx = 0
  fy = 0
  ex = ns
  ey = nl
  iproj = envi_get_projection(fid=fid)
  oproj = envi_proj_create(/geographic)
  print, 'content'

  x=fx
  y=fy
  envi_convert_file_coordinates, fid, x, y, xmap, ymap, /to_map
  envi_convert_projection_coordinates, xmap, ymap, iproj, oxmap, oymap, oproj ;;Lon = oxmap, Lat = oymap

  str=str+STRING(oxmap)+","
  str=str+STRING(oymap)+","
  x=ex
  y=ey
  envi_convert_file_coordinates, fid, x, y, xmap, ymap, /to_map
  envi_convert_projection_coordinates, xmap, ymap, iproj, oxmap, oymap, oproj ;;Lon = oxmap, Lat = oymap

  str=str+STRING(oxmap)+","
  str=str+STRING(oymap)+","
  envi_file_mng, id=fid, /remove ;;Don't forget to close file
  
  split2 = STRSPLIT(filename, '_', /PRESERVE_NULL, /EXTRACT)
  if (split2.LENGTH gt 5) then begin
    str=str+split2[5]+","
  endif
  print,str
  return, str
end
