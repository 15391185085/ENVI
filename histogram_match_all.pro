PRO histogram_match_all
;relative normalization
;������ɫ���ߣ�ֻ��ɫ����Ƕ
;ʹ��ֱ��ͼƥ�䷨
COMPILE_OPT IDL2
  ;Get ENVI session
  e = ENVI()
  
  filelist = DIALOG_PICKFILE(/MULTIPLE_FILES,FILTER = ['*.dat'], TITLE='ѡ���У��Ӱ��')
  print,filelist
  refname = DIALOG_PICKFILE(FILTER = ['*.dat'], TITLE='ѡ����ο�Ӱ��')
  print,refname
  RESPATH = DIALOG_PICKFILE(/DIRECTORY, TITLE='ѡ��У����Ӱ����·��')
  print,RESPATH
  
  ENVI_REPORT_INIT, ['У����Ӱ����·��: ' + RESPATH], title="��ɫ������...", base=base ,/INTERRUPT
  ENVI_REPORT_INC, base, filelist.LENGTH
  
  ;�����쳣
  CATCH, error_status
  FOR i=0,n_elements(filelist)-1 DO BEGIN    
    IF error_status NE 0 THEN BEGIN

      IF AdjustRaster NE !NULL THEN BEGIN
        AdjustRaster.Close
      ENDIF
      IF MatchedRaster NE !NULL THEN BEGIN
        MatchedRaster.Close
      ENDIF
      IF ReferenceRaster NE !NULL THEN BEGIN
        ReferenceRaster.Close
      ENDIF
      tmp = DIALOG_MESSAGE('�ļ���'+filelist[i] + "������ʧ��!",/info)
      ENVI_REPORT_INIT, base=base, /finish
      RETURN
    ENDIF
    
    print,'��ʼ'+systime()

    ;�ϳ�����ļ�λ��
    ENVI_REPORT_STAT,base, i, filelist.LENGTH, CANCEL=cancelvar
    ;�ж��Ƿ���ȡ��
    IF cancelVar EQ 1 THEN BEGIN
      tmp = DIALOG_MESSAGE('�����ȡ���ڵ�'+STRING(i)+'���ļ�',/info)
      ENVI_REPORT_INIT, base=base, /finish
      RETURN
    ENDIF
    
    filename=STRMID(filelist[i],0,STRLEN(filelist[i])-4)
    basename=FILE_BASENAME(filename)
    resname=respath+basename+'_histogram.dat'
    ;��ʼ��ɫ
    IF (FILE_TEST(resname) EQ 1) or (filelist[i] EQ refname) THEN BEGIN
      CONTINUE
    ENDIF
    ;��У���ʹ��ο�������һ��·���������·�����ܱ�ռ��
    ;��ȡ��У��Ӱ��
    ReferenceRaster = e.OpenRaster(refname, DATA_IGNORE_VALUE=0)
    AdjustRaster = e.OpenRaster(filelist[i], DATA_IGNORE_VALUE=0)
    tiles = AdjustRaster.CreateTileIterator(BANDS=0)
    Adjust_Sub_Rect = tiles.SUB_RECT

    IF ~N_ELEMENTS(AdjustRaster) THEN RETURN
    AdjustFile = AdjustRaster.URI
    
    ;����Adjustͼ��������Χ���ļ�����
    FileX = [Adjust_Sub_Rect[0], Adjust_Sub_Rect[2]]
    FileY = [Adjust_Sub_Rect[1], Adjust_Sub_Rect[3]]
    ;ת��Ϊ��������
    spatialRef1 = AdjustRaster.SPATIALREF
    spatialRef1.ConvertFileToMap, FileX, FileY, MapX, MapY

    ;����������Ƕդ�����������ɫͳ��ȫͼ
    Scenes = [AdjustRaster, ReferenceRaster]
    MosaicRaster = ENVIMOSAICRASTER(Scenes)
    MosaicRaster.COLOR_MATCHING_METHOD = 'histogram matching'
    MosaicRaster.COLOR_MATCHING_STATS = 'entire scene'
    MosaicRaster.COLOR_MATCHING_ACTIONS = ['adjust','reference']

    ;�������Χ�������꣬ת��Ϊ��Ƕ������ļ�����
    MatchedRaster = MosaicRaster.subset(SUB_RECT = [MapX[0],MapY[1],MapX[1],MapY[0]], $
      SPATIALREF = MosaicRaster.SPATIALREF)

    print,'�������:'+resname
    ;������
    MatchedRaster.export, resname, 'envi'
    print,'������'
    AdjustRaster.Close
    MatchedRaster.Close
    ReferenceRaster.Close
    print,'���'+systime()

  ENDFOR
  tmp = DIALOG_MESSAGE('������ɣ�',/info)
  ENVI_REPORT_INIT, base=base, /finish
  CATCH, /CANCEL
END