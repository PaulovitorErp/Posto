#INCLUDE "PROTHEUS.CH"
#INCLUDE "TBICONN.CH"
#INCLUDE "TopConn.ch"
#include "fileio.ch"
#INCLUDE "SHELL.CH"

Static lFatConv 	:= SuperGetMv("MV_XFTCONV",,.F.) //define se abrira modo faturamento conveniencia
Static cChavItem := ""

/*/{Protheus.doc} User Function TRETE048
Fatura em Excel

@type  Function
@author Danilo
@since 17/01/2024
@version 1
/*/
User Function TRETE048(oSay,_cFil,aFat,cObs) 

    Local aArea 	:= GetArea()
    Local aAreaSM0 	:= SM0->(GetArea())
    Local nH, nX
    Local cCaminho := GetTempPath()
    Local cArquivo := "fatura_"+DTOS(Date())+StrTran(Time(),":")  
    Local cBarra    := iif(GetRemoteType() > 1,"/","\")
    Local cCaminho2 := ""
    Local aFilesAba := {}

    if Right(cCaminho,1) == cBarra
        cCaminho := SubStr(cCaminho,1,len(cCaminho)-1)
    endif
    cCaminho2 := cCaminho+cBarra+cArquivo

    Private cFilFat			:= _cFil

    If !File(cCaminho2)
        If MakeDir(cCaminho2) <> 0
            MsgAlert("Nao foi possivel criar o diretorio "+cCaminho2+". Operação abortada!")
            Return
        EndIf
    EndIf

    For nX := 1 To Len(aFat)
        aadd(aFilesAba, {aFat[nX][1],"fat_"+aFat[nX][1]+"_"+DTOS(Date())+StrTran(Time(),":")+".htm" } )
    Next nX

    //ARQUIVO PRINCIPAL - DEFINICAO ABAS
    nH := fCreate(cCaminho+cBarra+cArquivo+".htm",FC_NORMAL) //cria arquivo
    If nH == -1
        MsgStop("Falha ao criar arquivo "+cCaminho+cBarra+cArquivo+".htm"+". Pode ser que o arquivo ja esteja criado e aberto!")
        Return
    Endif
    
    fWrite( nH, '<html xmlns:v="urn:schemas-microsoft-com:vml" xmlns:o="urn:schemas-microsoft-com:office:office" xmlns:x="urn:schemas-microsoft-com:office:excel">' + CRLF)
    fWrite( nH, '<head>' + CRLF)
    fWrite( nH, '<meta name="Excel Workbook Frameset">' + CRLF)
    fWrite( nH, '<meta http-equiv=Content-Type content="text/html; charset=windows-1252">' + CRLF)
    fWrite( nH, '<meta name=ProgId content=Excel.Sheet>' + CRLF)
    fWrite( nH, '<meta name=Generator content="Microsoft Excel 15">' + CRLF)
    fWrite( nH, '<!--[if gte mso 9]><xml>' + CRLF)
    fWrite( nH, '<x:ExcelWorkbook>' + CRLF)
    fWrite( nH, '<x:ExcelWorksheets>' + CRLF)
    
    for nX := 1 to len(aFilesAba)
        fWrite( nH, '<x:ExcelWorksheet>' + CRLF)
        fWrite( nH, '<x:Name>'+aFilesAba[nX][1]+'</x:Name>' + CRLF)
        fWrite( nH, '<x:WorksheetSource HRef="'+cCaminho2+"/"+aFilesAba[nX][2]+'"/>' + CRLF)
        fWrite( nH, '</x:ExcelWorksheet>' + CRLF)
    next nX
    
    fWrite( nH, '</x:ExcelWorksheets>' + CRLF)
    fWrite( nH, '</x:ExcelWorkbook>' + CRLF)
    fWrite( nH, '</xml><![endif]-->' + CRLF)
    fWrite( nH, '</head>' + CRLF)
    fWrite( nH, '<frameset rows="*,39" border=0 width=0 frameborder=no framespacing=0>' + CRLF)
    fWrite( nH, '    <frame src="'+cCaminho2+"/"+aFilesAba[1][2]+'" name="frSheet">' + CRLF)
    fWrite( nH, '    <frame src="'+cCaminho2+'/tabstrip.htm" name="frTabs" marginwidth=0 marginheight=0>' + CRLF)
    fWrite( nH, '</frameset>' + CRLF)

    fWrite( nH, '</html>' + CRLF)
    fWrite( nH, '' + CRLF)

    fClose( nH ) //Fecha o arquivo

    //ARQUIVO tabstrip
    nH := fCreate(cCaminho2+cBarra+"tabstrip.htm",FC_NORMAL) //cria arquivo
    If nH == -1
        MsgStop("Falha ao criar arquivo "+cCaminho2+cBarra+"tabstrip.htm"+". Pode ser que o arquivo ja esteja criado e aberto!")
        Return
    Endif

    fWrite( nH, '<html>' + CRLF)
    fWrite( nH, '<head>' + CRLF)
    fWrite( nH, '<meta http-equiv=Content-Type content="text/html; charset=windows-1252">' + CRLF)
    fWrite( nH, '<meta name=ProgId content=Excel.Sheet>' + CRLF)
    fWrite( nH, '<meta name=Generator content="Microsoft Excel 15">' + CRLF)
    fWrite( nH, '<link id=Main-File rel=Main-File href="../'+cArquivo+'.htm">' + CRLF)
    fWrite( nH, '<script language="JavaScript">' + CRLF)
    fWrite( nH, 'if (window.name!="frTabs")' + CRLF)
    fWrite( nH, ' window.location.replace(document.all.item("Main-File").href);' + CRLF)
    fWrite( nH, '</script>' + CRLF)
    fWrite( nH, '<style>' + CRLF)
    fWrite( nH, 'A {' + CRLF)
    fWrite( nH, '    text-decoration:none;' + CRLF)
    fWrite( nH, '    color:#000000;' + CRLF)
    fWrite( nH, '    font-size:9pt;' + CRLF)
    fWrite( nH, '}' + CRLF)
    fWrite( nH, '</style>' + CRLF)
    fWrite( nH, '</head>' + CRLF)
    fWrite( nH, '<body topmargin=0 leftmargin=0 bgcolor="#808080">' + CRLF)
    fWrite( nH, '<table border=0 cellspacing=1>' + CRLF)
    fWrite( nH, '<tr>' + CRLF)
    for nX := 1 to len(aFilesAba)
        fWrite( nH, '<td bgcolor="#FFFFFF" nowrap><b><small><small>&nbsp;<a href="'+aFilesAba[nX][2]+'" target="frSheet"><font face="Arial" color="#000000">'+aFilesAba[nX][1]+'</font></a>&nbsp;</small></small></b></td>' + CRLF)
    next nX
    fWrite( nH, '</tr>' + CRLF)
    fWrite( nH, '</table>' + CRLF)
    fWrite( nH, '</body>' + CRLF)
    fWrite( nH, '</html>' + CRLF)

    fClose( nH ) //Fecha o arquivo

    //ARQUIVO CSS stylesheet.css
    nH := fCreate(cCaminho2+cBarra+"stylesheet.css",FC_NORMAL) //cria arquivo
    If nH == -1
        MsgStop("Falha ao criar arquivo "+cCaminho2+cBarra+"stylesheet.css . Pode ser que o arquivo ja esteja criado e aberto!")
        Return
    Endif
    DoStylesCSS(nH)
    fClose( nH ) //Fecha o arquivo

    //ARQUIVOS DA FATURA POR ABA
    For nX := 1 To Len(aFat)

        If !IsBlind() .And. oSay <> Nil
            oSay:cCaption := "Imprimindo fatura "+cValToChar(nX)+" de "+cValToChar(Len(aFat))+""
            ProcessMessages()
        Endif
        
        //ARQUIVO CSS stylesheet.css
        nH := fCreate(cCaminho2+cBarra+aFilesAba[nX][2],FC_NORMAL) //cria arquivo
        If nH == -1
            MsgStop("Falha ao criar arquivo "+cCaminho2+cBarra+aFilesAba[nX][2]+". Pode ser que o arquivo ja esteja criado e aberto!")
            Return
        Endif
        
        DoImpFat(nH, aFat[nX], cObs)

        fClose( nH ) //Fecha o arquivo
        
    Next nX

    If GetRemoteType() == 1 //se 1 é windows

        //converto o arquivo htm para xlsx
        //if PsExecute(cCaminho+cBarra, cArquivo+".ps1", cArquivo+".htm", cArquivo+".xlsx" )
        //    //Abrindo o excel e abrindo o arquivo xlsx
        //    ShellExecute( "Open", "excel.exe", cCaminho+cBarra+cArquivo+".xlsx", "C:\", 3 )
        //
        //    DelFiles(cCaminho+cBarra+cArquivo+".htm", cCaminho2+cBarra )
        //else
            //Abrindo o excel e abrindo o arquivo htm
            ShellExecute( "Open", "excel.exe", cCaminho+cBarra+cArquivo+".htm", "C:\", 3 )
        //endif
        
        Sleep(3000)//aguarda 3 segundos
        
    else

        //Abrindo o excel e abrindo o arquivo xml
        ShellExecute( "Open", cCaminho+cBarra+cArquivo+".htm", "", "", 3 )
        Sleep(3000)//aguarda 3 segundos

    endif

    RestArea(aAreaSM0)
    RestArea(aArea)

Return

Static Function DoStylesCSS(nH)

    Local cHtml := ''
    
    cHtml += 'td{ ' + CRLF
    cHtml += '    padding:1px; ' + CRLF
    cHtml += '    font-size:11.0pt; ' + CRLF
    cHtml += '    font-family:Calibri, sans-serif; ' + CRLF
    cHtml += '    white-space:nowrap; ' + CRLF
    cHtml += '} ' + CRLF
    cHtml += '.title_1 { ' + CRLF
    cHtml += '    font-size:14.0pt; ' + CRLF
    cHtml += '    text-align:center; ' + CRLF
    cHtml += '    font-weight:700; ' + CRLF
    cHtml += '    border:.5pt solid windowtext; ' + CRLF
    cHtml += '    background:#D9E1F2; ' + CRLF
    cHtml += '    vertical-align:middle; ' + CRLF
    cHtml += '} ' + CRLF
    cHtml += '.title_2 { ' + CRLF
    cHtml += '    font-size:14.0pt; ' + CRLF
    cHtml += '    font-weight:700; ' + CRLF
    cHtml += '    vertical-align:middle; ' + CRLF
    cHtml += '} ' + CRLF
    cHtml += '.title_3 { ' + CRLF
    cHtml += '    color:white; ' + CRLF
    cHtml += '    font-size:10.0pt; ' + CRLF
    cHtml += '    font-weight:700; ' + CRLF
    cHtml += '    text-align:center; ' + CRLF
    cHtml += '    border-left:.5pt solid windowtext; ' + CRLF
    cHtml += '    border-right  :.5pt solid windowtext; ' + CRLF
    cHtml += '    background:#4472C4; ' + CRLF
    cHtml += '    vertical-align:middle; ' + CRLF
    cHtml += '} ' + CRLF
    cHtml += '.title_4 { ' + CRLF
    cHtml += '    font-size:12.0pt; ' + CRLF
    cHtml += '    font-weight:700; ' + CRLF
    cHtml += '    vertical-align:middle; ' + CRLF
    cHtml += '} ' + CRLF
    cHtml += '.title_4_r { ' + CRLF
    cHtml += '    font-size:12.0pt; ' + CRLF
    cHtml += '    font-weight:700; ' + CRLF
    cHtml += '    mso-number-format:Fixed; ' + CRLF
    cHtml += '    text-align:right; ' + CRLF
    cHtml += '    vertical-align:middle; ' + CRLF
    cHtml += '} ' + CRLF
    cHtml += '.empty_t3_tlr { ' + CRLF
    cHtml += '    border-top:.5pt solid windowtext; ' + CRLF
    cHtml += '    border-left:.5pt solid windowtext; ' + CRLF
    cHtml += '    border-right  :.5pt solid windowtext; ' + CRLF
    cHtml += '    background:#4472C4; ' + CRLF
    cHtml += '    vertical-align:middle; ' + CRLF
    cHtml += '} ' + CRLF
    cHtml += '.empty_t3_blr { ' + CRLF
    cHtml += '    border-bottom:.5pt solid windowtext; ' + CRLF
    cHtml += '    border-left:.5pt solid windowtext; ' + CRLF
    cHtml += '    border-right  :.5pt solid windowtext; ' + CRLF
    cHtml += '    background:#4472C4; ' + CRLF
    cHtml += '    vertical-align:middle; ' + CRLF
    cHtml += '} ' + CRLF

    cHtml += '.empty_t{ ' + CRLF
    cHtml += '    border-top:.5pt solid windowtext; ' + CRLF
    cHtml += '} ' + CRLF
    cHtml += '.empty_l{ ' + CRLF
    cHtml += '    border-left:.5pt solid windowtext; ' + CRLF
    cHtml += '} ' + CRLF
    cHtml += '.empty_r{ ' + CRLF
    cHtml += '    border-right:.5pt solid windowtext; ' + CRLF
    cHtml += '} ' + CRLF
    cHtml += '.empty_b{ ' + CRLF
    cHtml += '    border-bottom:.5pt solid windowtext; ' + CRLF
    cHtml += '} ' + CRLF
    cHtml += '.empty_tl{ ' + CRLF
    cHtml += '    border-top:.5pt solid windowtext; ' + CRLF
    cHtml += '    border-left:.5pt solid windowtext; ' + CRLF
    cHtml += '} ' + CRLF
    cHtml += '.empty_tr{ ' + CRLF
    cHtml += '    border-top:.5pt solid windowtext; ' + CRLF
    cHtml += '    border-right  :.5pt solid windowtext; ' + CRLF
    cHtml += '} ' + CRLF
    cHtml += '.empty_bl{ ' + CRLF
    cHtml += '    border-bottom:.5pt solid windowtext; ' + CRLF
    cHtml += '    border-left:.5pt solid windowtext; ' + CRLF
    cHtml += '} ' + CRLF
    cHtml += '.empty_br{ ' + CRLF
    cHtml += '    border-bottom:.5pt solid windowtext; ' + CRLF
    cHtml += '    border-right  :.5pt solid windowtext; ' + CRLF
    cHtml += '} ' + CRLF
    cHtml += '.tx8 { ' + CRLF
    cHtml += '    font-size:8.0pt; ' + CRLF
    cHtml += '    vertical-align:middle; ' + CRLF
    cHtml += '    white-space:normal; ' + CRLF
    cHtml += '} ' + CRLF
    cHtml += '.tx10 { ' + CRLF
    cHtml += '    font-size:10.0pt; ' + CRLF
    cHtml += '    vertical-align:middle; ' + CRLF
    //cHtml += '    white-space:normal; ' + CRLF
    cHtml += '} ' + CRLF
    cHtml += '.tx10_ar { ' + CRLF
    cHtml += '    font-size:10.0pt; ' + CRLF
    cHtml += '    text-align:right; ' + CRLF
    cHtml += '    vertical-align:middle; ' + CRLF
    //cHtml += '    white-space:normal; ' + CRLF
    cHtml += '} ' + CRLF
    cHtml += '.tx10_lr { ' + CRLF
    cHtml += '    font-size:10.0pt; ' + CRLF
    cHtml += '    text-align:center; ' + CRLF
    cHtml += '    vertical-align:middle; ' + CRLF
    //cHtml += '    white-space:normal; ' + CRLF
    cHtml += '    border-left:.5pt solid windowtext; ' + CRLF
    cHtml += '    border-right  :.5pt solid windowtext; ' + CRLF
    cHtml += '} ' + CRLF
    cHtml += '.tx11b { ' + CRLF
    cHtml += '    font-size:11.0pt; ' + CRLF
    cHtml += '    font-weight:700; ' + CRLF
    cHtml += '    vertical-align:middle; ' + CRLF
    //cHtml += '    white-space:normal; ' + CRLF
    cHtml += '} ' + CRLF
    cHtml += '.tx11b_lr { ' + CRLF
    cHtml += '    font-size:11.0pt; ' + CRLF
    cHtml += '    font-weight:700; ' + CRLF
    cHtml += '    text-align:center; ' + CRLF
    cHtml += '    vertical-align:middle; ' + CRLF
    //cHtml += '    white-space:normal; ' + CRLF
    cHtml += '    border-left:.5pt solid windowtext; ' + CRLF
    cHtml += '    border-right  :.5pt solid windowtext; ' + CRLF
    cHtml += '} ' + CRLF
    cHtml += '.tx11b_ar { ' + CRLF
    cHtml += '    font-size:11.0pt; ' + CRLF
    cHtml += '    font-weight:700; ' + CRLF
    cHtml += '    mso-number-format:Fixed; ' + CRLF
    cHtml += '    text-align:right; ' + CRLF
    cHtml += '    vertical-align:middle; ' + CRLF
    //cHtml += '    white-space:normal; ' + CRLF
    cHtml += '} ' + CRLF

    cHtml += '.head_item{ ' + CRLF
    cHtml += '    text-align:center; ' + CRLF
    cHtml += '    font-size:10.0pt; ' + CRLF
    cHtml += '    font-weight:700; ' + CRLF
    cHtml += '    vertical-align:middle; ' + CRLF
    cHtml += '    border:.5pt solid windowtext; ' + CRLF
    cHtml += '    background:#D9E1F2; ' + CRLF
    //cHtml += '    white-space:normal; ' + CRLF
    cHtml += '} ' + CRLF

    cHtml += '.data_item{ ' + CRLF
    cHtml += '    text-align:left; ' + CRLF
    cHtml += '    font-size:10.0pt; ' + CRLF
    cHtml += '    vertical-align:middle; ' + CRLF
    cHtml += '    border-left:.5pt solid windowtext; ' + CRLF
    cHtml += '    border-right  :.5pt solid windowtext; ' + CRLF
    //cHtml += '    white-space:normal; ' + CRLF
    cHtml += '} ' + CRLF
    cHtml += '.data_item_center{ ' + CRLF
    cHtml += '    text-align:center; ' + CRLF
    cHtml += '    font-size:10.0pt; ' + CRLF
    cHtml += '    vertical-align:middle; ' + CRLF
    cHtml += '    border-left:.5pt solid windowtext; ' + CRLF
    cHtml += '    border-right  :.5pt solid windowtext; ' + CRLF
    //cHtml += '    white-space:normal; ' + CRLF
    cHtml += '} ' + CRLF
    cHtml += '.data_item_center_number{ ' + CRLF
    cHtml += '    text-align:center; ' + CRLF
    cHtml += '    font-size:10.0pt; ' + CRLF
    cHtml += '    mso-number-format:Fixed; ' + CRLF
    cHtml += '    vertical-align:middle; ' + CRLF
    cHtml += '    border-left:.5pt solid windowtext; ' + CRLF
    cHtml += '    border-right  :.5pt solid windowtext; ' + CRLF
    //cHtml += '    white-space:normal; ' + CRLF
    cHtml += '} ' + CRLF
    cHtml += '.data_item_right{ ' + CRLF
    cHtml += '    text-align:right; ' + CRLF
    cHtml += '    font-size:10.0pt; ' + CRLF
    cHtml += '    mso-number-format:Fixed; ' + CRLF
    cHtml += '    vertical-align:middle; ' + CRLF
    cHtml += '    border-left:.5pt solid windowtext; ' + CRLF
    cHtml += '    border-right  :.5pt solid windowtext; ' + CRLF
    //cHtml += '    white-space:normal; ' + CRLF
    cHtml += '} ' + CRLF

    cHtml += '.data_tot_left{ ' + CRLF
    cHtml += '    text-align:left; ' + CRLF
    cHtml += '    font-size:10.0pt; ' + CRLF
    cHtml += '    font-weight:700; ' + CRLF
    cHtml += '    vertical-align:middle; ' + CRLF
    cHtml += '    border-top:.5pt solid windowtext; ' + CRLF
    cHtml += '    border-left:.5pt solid windowtext; ' + CRLF
    cHtml += '    border-right  :.5pt solid windowtext; ' + CRLF
    //cHtml += '    white-space:normal; ' + CRLF
    cHtml += '} ' + CRLF
    cHtml += '.data_tot_right{ ' + CRLF
    cHtml += '    text-align:right; ' + CRLF
    cHtml += '    font-size:10.0pt; ' + CRLF
    cHtml += '    font-weight:700; ' + CRLF
    cHtml += '    vertical-align:middle; ' + CRLF
    cHtml += '    border-top:.5pt solid windowtext; ' + CRLF
    cHtml += '    border-left:.5pt solid windowtext; ' + CRLF
    cHtml += '    border-right  :.5pt solid windowtext; ' + CRLF
    //cHtml += '    white-space:normal; ' + CRLF
    cHtml += '} ' + CRLF

    fWrite( nH, cHtml)

Return

Static Function DoImpFat(nH, aFatImp, cObs)

    Local lOk := .T.

    Private aSizeCols := {"030","094","086","096","085","111","080","080","114","096","096","090","116","116","030"}
    Private nWidthTable := 0 //tamanho total da tabela
    Private nColSpan := len(aSizeCols)

    Private	nTotQtd 		:= 0
    Private	nTotVlr			:= 0

    Private cFil			:= ""
    Private cFatSol			:= ""
    Private cSubAgrup		:= ""
    Private cClasse			:= ""
    Private nVlrAcres		:= 0
    Private nVlrDecres		:= 0
    Private lDanfe			:= .F.
    Private lHasVend		:= .F.
    Private lHasAbast		:= .F.
    Private lDuplSD2 		:= .F.

    aEval(aSizeCols, {|cCol| nWidthTable += val(cCol) })

    lOk := DoHeader(nH, aFatImp)
    if lOk
        lDanfe		:= RetDanfe(aFatImp)

        DoItens(nH, aFatImp)
        DoCompItens(nH, aFatImp)
        DoDadosFil(nH, aFatImp, cObs)
        DoResumo(nH, aFatImp)
    endif
    DoFooter(nH, lOk)

Return

//Funçao para montar cabeçalho do arquivo a ser aberto
Static Function DoHeader(nH, _aFat) 

    Local cHtml := ''
    Local aClass, aColspan, aContent
    Local lOK := .T.

    Local cQry 			:= ""
    Local cNome 		:= ""
    Local cEnd 			:= ""
    Local cComp 		:= ""
    Local cBairro		:= ""
    Local cMun 			:= ""
    Local cCep 			:= ""
    Local cEst 			:= ""
    Local cInscr 		:= ""
    Local cCgc			:= ""
    Local cTel			:= ""
    Local cCli			:= ""
    Local cLoja			:= ""
    Local cEmis			:= ""
    Local cVencto		:= ""

    Local aFil			:= {}

    If Select("QRYCABEC") > 0
        QRYCABEC->(DbCloseArea())
    Endif

    cQry := "SELECT SA1.A1_NOME, ISNULL(U88.U88_END,'') AS U88_END, U88.U88_COMPLE, U88.U88_BAIRRO, U88.U88_MUN, U88.U88_CEP, U88.U88_EST, U88.U88_INSCR, U88.U88_CGC,"
    cQry += CRLF + " U88.U88_TEL, U88.U88_FATCOR, SA1.A1_END, SA1.A1_COMPLEM, SA1.A1_BAIRRO, SA1.A1_MUN, SA1.A1_CEP, SA1.A1_EST, SA1.A1_INSCR, SA1.A1_CGC, SA1.A1_PESSOA,"
    cQry += CRLF + " SA1.A1_TEL, SE1.E1_CLIENTE, SE1.E1_LOJA, SE1.E1_FILIAL, SE1.E1_EMISSAO, SE1.E1_VENCTO, SE1.E1_VENCREA, SA1.A1_XQFAT, 

    If !lFatConv // Diferente de conveniência
        cQry += CRLF + " UF6.UF6_DESC,"
    EndIf
    cQry += CRLF + " SE1.E1_ACRESC, SE1.E1_DECRESC"

    cQry += CRLF + " FROM "+RetSqlName("SE1")+" SE1 	INNER JOIN "+RetSqlName("SA1")+" SA1 ON SE1.E1_CLIENTE 		= SA1.A1_COD"
    cQry += CRLF + " 																			AND SE1.E1_LOJA		= SA1.A1_LOJA"
    cQry += CRLF + " 																			AND SA1.D_E_L_E_T_ = ' '"

    cQry += CRLF + "									LEFT JOIN "+RetSqlName("U88")+" U88  ON SE1.E1_CLIENTE 		= U88.U88_CLIENT"
    cQry += CRLF + " 																			AND SE1.E1_LOJA		= U88.U88_LOJA"
    cQry += CRLF + " 																			AND SE1.E1_TIPO		= LEFT(U88.U88_FORMAP,3)"
    cQry += CRLF + " 																			AND U88.D_E_L_E_T_ = ' '"
    cQry += CRLF + " 																			AND U88.U88_FILIAL	= '"+xFilial("U88",cFilFat)+"'"

    If !lFatConv // Diferente de conveniência
        cQry += CRLF + " 									LEFT JOIN "+RetSqlName("UF6")+" UF6		ON SA1.A1_XCLASSE	= UF6.UF6_CODIGO"
        cQry += CRLF + " 																			AND UF6.D_E_L_E_T_ = ' '"
        cQry += CRLF + " 																			AND UF6.UF6_FILIAL	= '"+xFilial("UF6")+"'"
    EndIf

    cQry += CRLF + " WHERE SE1.D_E_L_E_T_	= ' '"
    cQry += CRLF + " AND SE1.E1_FILIAL		= '"+xFilial("SE1",cFilFat)+"'"
    cQry += CRLF + " AND SE1.E1_NUM			= '"+_aFat[1]+"'"
    cQry += CRLF + " AND SE1.E1_CLIENTE		= '"+_aFat[2]+"'"
    cQry += CRLF + " AND SE1.E1_LOJA		= '"+_aFat[3]+"'"

    If Len(_aFat) > 3
        cQry += CRLF + " AND SE1.E1_PREFIXO	= '"+_aFat[4]+"'"
        cQry += CRLF + " AND SE1.E1_PARCELA	= '"+_aFat[5]+"'"
        cQry += CRLF + " AND SE1.E1_TIPO	= '"+_aFat[6]+"'"
    Endif

    cQry := ChangeQuery(cQry)
    //MemoWrite("c:\temp\RFATE013_cabec.txt",cQry)
    TcQuery cQry NEW Alias "QRYCABEC"

    If QRYCABEC->(!EOF())

        cNome := QRYCABEC->A1_NOME
        cFatSol		:= IIF(QRYCABEC->U88_FATCOR == "S","Não","Sim")

        If !Empty(QRYCABEC->U88_END)
            cEnd 		:= QRYCABEC->U88_END
            cComp 		:= QRYCABEC->U88_COMPLE
            cBairro		:= QRYCABEC->U88_BAIRRO
            cMun 		:= QRYCABEC->U88_MUN
            cCep 		:= Transform(QRYCABEC->U88_CEP,"@R 99999-999")
            cEst 		:= QRYCABEC->U88_EST
            cInscr 		:= QRYCABEC->U88_INSCR
            cCgc		:= Subs(Transform(QRYCABEC->U88_CGC,PicPes(RetPessoa(QRYCABEC->U88_CGC))),1,At("%",Transform(QRYCABEC->U88_CGC,PicPes(RetPessoa(QRYCABEC->U88_CGC))))-1)
            cTel		:= QRYCABEC->U88_TEL
        Else
            cEnd 		:= QRYCABEC->A1_END
            cComp 		:= QRYCABEC->A1_COMPLEM
            cBairro		:= QRYCABEC->A1_BAIRRO
            cMun 		:= QRYCABEC->A1_MUN
            cCep 		:= Transform(QRYCABEC->A1_CEP,"@R 99999-999")
            cEst 		:= QRYCABEC->A1_EST
            cInscr 		:= QRYCABEC->A1_INSCR
            cCgc		:= Subs(Transform(QRYCABEC->A1_CGC,PicPes(RetPessoa(QRYCABEC->A1_CGC))),1,At("%",Transform(QRYCABEC->A1_CGC,PicPes(RetPessoa(QRYCABEC->A1_CGC))))-1)
            cTel		:= QRYCABEC->A1_TEL
        Endif

        cCli		:= QRYCABEC->E1_CLIENTE
        cLoja		:= QRYCABEC->E1_LOJA
        cFil		:= QRYCABEC->E1_FILIAL
        cEmis		:= DToC(SToD(QRYCABEC->E1_EMISSAO))
        cVencto		:= DToC(SToD(QRYCABEC->E1_VENCREA)) //E1_VENCTO
        cSubAgrup	:= QRYCABEC->A1_XQFAT

        If !lFatConv // Diferente de conveniência
            cClasse		:= QRYCABEC->UF6_DESC
        EndIf
        
        nVlrAcres	:= QRYCABEC->E1_ACRESC
        nVlrDecres	:= QRYCABEC->E1_DECRESC
    Else
        Conout("Dados não localizados!")
        lOK := .F.
    Endif

    If Select("QRYCABEC") > 0
        QRYCABEC->(dbCloseArea())
    Endif

    DbSelectArea("SM0")
	SM0->(DbSetOrder(1))
	SM0->(DbSeek(cEmpAnt+cFil))
	if SM0->(Eof())
		SM0->(DbSeek(cEmpAnt+cFilAnt))
	endif
	aFil := U_UQuebTxt(SM0->M0_FILIAL,13)


    cHtml += '<html>' + CRLF
    cHtml += '<head>' + CRLF
    cHtml += '<meta http-equiv="Content-Type" content="text/html; charset=windows-1252">' + CRLF
    cHtml += '<link rel="stylesheet" href="stylesheet.css">' + CRLF
    cHtml += '</head>' + CRLF
    cHtml += '<body>' + CRLF

    cHtml += '<table border="0" cellpadding="0" cellspacing="0" width="'+cValToChar(nWidthTable)+'">' + CRLF
    
    cHtml += DoPrintLin("30",,{"title_1"},{nColSpan},{"FATURA DE CLIENTE"})

    //crio linha em branco com tamanho de cada coluna utilizada    
    cHtml += DoPrintLin("10", aSizeCols)

    if lOK

        aClass := {"empty_tl","empty_t","empty_t","empty_t","empty_t","empty_t","empty_t","empty_t","empty_t","empty_t","empty_t","empty_tr","empty_tr","empty_t","empty_tr"}
        cHtml += DoPrintLin(,,aClass)
        
        aClass := {"empty_l","title_2","tx10_lr","tx10_lr"}
        aColspan := {0,11,0,2}
        aContent := {"",cNome,"Sacado","Fatura"}
        cHtml += DoPrintLin(,,aClass,aColspan,aContent)

        aClass := {"empty_l","","tx11b_lr","tx11b_lr"}
        aColspan := {0,11,0,2}
        aContent := {"","",AllTrim(cCli) + "/" + cLoja+"&nbsp;",_aFat[1]+"&nbsp;"}
        cHtml += DoPrintLin(,,aClass,aColspan,aContent)

        aClass := {"empty_l","tx10","tx11b","empty_l","empty_l","empty_r"}
        aColspan := {0,0,10,0,0,0}
        aContent := {"","Endereço:",cEnd,"","",""}
        cHtml += DoPrintLin(,,aClass,aColspan,aContent)

        aClass := {"empty_l","tx10","tx11b","tx10","tx11b","empty_t3_tlr","tx10_lr"}
        aColspan := {0,0,7,0,2,0,2}
        aContent := {"","Compl.:",cComp,"I.E.:",cInscr+"&nbsp;","","Emissão"}
        cHtml += DoPrintLin(,,aClass,aColspan,aContent)

        aClass := {"empty_l","tx10","tx11b","tx10","tx11b","title_3","tx11b_lr"}
        aColspan := {0,0,7,0,2,0,2}
        aContent := {"","Bairro:",cBairro,"CNPJ:",cCgc,iif(len(aFil)>=1,aFil[1],""),cEmis}
        cHtml += DoPrintLin(,,aClass,aColspan,aContent)

        aClass := {"empty_l","tx10","tx11b","tx10","tx11b","","","","","title_3","empty_l","empty_r"}
        aColspan := {0,0,4,0,0,0,0,0,0,0,0,0}
        aContent := {"","Cidade:",cMun,"U.F.:",cEst,"","","","",iif(len(aFil)>=2,aFil[2],""),"",""}
        cHtml += DoPrintLin(,,aClass,aColspan,aContent)

        aClass := {"empty_l","tx10","tx11b","tx10","tx11b","title_3","tx10_lr"}
        aColspan := {0,0,7,0,2,0,2}
        aContent := {"","CEP:",cCep,"Fone:",cTel+"&nbsp;",iif(len(aFil)>=3,aFil[3],""),"Vencimento"}
        cHtml += DoPrintLin(,,aClass,aColspan,aContent)

        aClass := {"empty_l","","","","","","","","","","","","title_3","tx11b_lr"}
        aColspan := {0,0,0,0,0,0,0,0,0,0,0,0,0,2}
        aContent := {"","","","","","","","","","","","",iif(len(aFil)>=4,aFil[4],""),cVencto}
        cHtml += DoPrintLin(,,aClass,aColspan,aContent)

        aClass := {"empty_bl","empty_b","empty_b","empty_b","empty_b","empty_b","empty_b","empty_b","empty_b","empty_b","empty_b","empty_b","empty_t3_blr","empty_b","empty_br"}
        cHtml += DoPrintLin(,,aClass)

        //linha em branco separadora de sessao
        cHtml += DoPrintLin()

    else
        cHtml += DoPrintLin(,,,{nColSpan},"Dados da fatura não localizados!")

    endif

    //ajusto colocando o 3D após os caracteres =
    //cHtml := StrTran(cHtml,'="','=3D"')

    fWrite( nH, cHtml)

Return lOK

//Impressao de linhas
/*
    cHeight: define a altura da linha
    aWidth: define o tamanho de cada coluna
    aClass: define a classe de estilo css de cada coluna
    aColspan: define a mescla de colunas
    aContent: define o conteudo de cada coluna
*/
Static Function DoPrintLin(cHeight, aWidth, aClass, aColspan, aContent)

    Local nX := 1
    Local cHtml := ''
    Local nLenCols := 0
    Default cHeight := "24"
    
    nLenCols := iif(aWidth <> Nil, len(aWidth), iif(aClass <> Nil, len(aClass), iif(aColspan <> Nil, len(aColspan), iif(aContent <> Nil, len(aContent), nColSpan ) ) ) )
    if aWidth == Nil
        aWidth := Array(nLenCols)
    endif
    if aClass == Nil
        aClass := Array(nLenCols)
    endif
    if aColspan == Nil
        aColspan := Array(nLenCols)
    endif
    if aContent == Nil
        aContent := Array(nLenCols)
    endif

    cHtml += '<tr height="'+cHeight+'">' + CRLF

    for nX := 1 to nLenCols
        cHtml += '    <td'+;
                        iif(!empty(aWidth[nX]),' width="'+aWidth[nX]+'"','')+;
                        iif(!empty(aClass[nX]),' class="'+aClass[nX]+'"','')+;
                        iif(!empty(aColspan[nX]),' colspan="'+cValToChar(aColspan[nX])+'"','')+;
                        '>'+;
                        iif(!empty(aContent[nX]),aContent[nX],'');
                        +'</td>' + CRLF    
    next nX

    cHtml += '</tr>' + CRLF

Return cHtml

Static Function DoItens(nH, _aFat)

    Local nX
    Local nQtdLin := 1
    Local nQtdMinLin := 15
    Local cHtml := ''
    Local aClass, aColspan, aContent
    
    Local cQry          := ""
    Local cFPg			:= ""
    Local cMotSaq		:= ""
    Local lDifFpg 		:= .F.
    Local lDifMotSaq	:= .F.
    Local aItens		:= {}
    Local nSubVlr		:= 0
    Local nValDesc      := 0

    Local aRecSD2 := {}

    nTotQtd := 0
    nSubVlr := 0
    nTotVlr := 0
    
    //Tipo de subagrupamento dos itens
    If !lFatConv // Diferente de conveniência
        Do Case
            Case cSubAgrup == "F"
                cHtml += DoPrintLin(,,{"","tx10",""},{0,13,0},{"","Subagrupado por: Tipo de Pagamento",""})
            Case cSubAgrup == "M"
                cHtml += DoPrintLin(,,{"","tx10",""},{0,13,0},{"","Subagrupado por: Motivo de Saque",""})
        EndCase
    EndIf

    //Cabeçalho dos itens
    aClass := {"head_item","head_item","head_item","head_item","head_item","head_item","head_item","head_item","head_item","head_item","head_item"}
    aColspan := {2,0,0,0,0,3,0,0,0,0,2}
    aContent := {"Titulo","Filial","Emissão","Placa","Motorista","Item (produto/serviço)","Qtde.","R$ Unit.","KM","Desconto","Valor Tot."}
    cHtml += DoPrintLin(,,aClass,aColspan,aContent)

    //ajusto colocando o 3D após os caracteres =
    //cHtml := StrTran(cHtml,'="','=3D"')

    fWrite( nH, cHtml)

    cHtml := ''
    If Select("QRYITENS") > 0
        QRYITENS->(dbCloseArea())
    Endif

    If !lFatConv // Diferente de conveniência
        cQry := "SELECT SE1.E1_FILORIG, SE1.E1_TIPO, SE1.E1_NUM, SE1.E1_NUMCART, SE1.E1_PARCELA, SE1.E1_EMISSAO, SE1.E1_XPLACA, SD2.D2_QUANT AS QTD, SD2.D2_COD AS PROD, "
        cQry += " SL1.L1_ODOMETR, SL1.L1_NOMMOTO, SL1.L1_CGCMOTO as L1_CGCCLI, U57.U57_MOTIVO, SE1.E1_VALOR, SE1.E1_VLRREAL, SE1.E1_PREFIXO, SE1.E1_CLIENTE, SE1.E1_LOJA, UIC.UIC_PLACA,"
        cQry += " UIC.UIC_MOTORI, UIC.UIC_PRODUT, UIC.UIC_PRCPRO, SA1.A1_NREDUZ, SA1.A1_EST, SA1.A1_MUN, SL1.L1_NUM, SD2.D2_ITEM, SD2.D2_PRCVEN, E1_XMOTOR, SD2.R_E_C_N_O_ RECSD2"
    Else
        cQry := "SELECT SE1.E1_FILORIG, SE1.E1_TIPO, SE1.E1_NUM, SE1.E1_PARCELA, SE1.E1_EMISSAO, SD2.D2_QUANT AS QTD, SD2.D2_COD AS PROD, "
        cQry += " SE1.E1_VALOR, SE1.E1_VLRREAL, SE1.E1_PREFIXO, SE1.E1_CLIENTE, SE1.E1_LOJA,"
        cQry += " SA1.A1_NREDUZ, SA1.A1_EST, SA1.A1_MUN, SD2.D2_ITEM, SD2.D2_PRCVEN, E1_XMOTOR, SD2.R_E_C_N_O_ RECSD2"
    EndIf 

    cQry += CRLF + " FROM "+RetSqlName("SE1")+" SE1 LEFT JOIN "+RetSqlName("SF2")+" SF2"
    cQry += CRLF + " ON SF2.D_E_L_E_T_ = ' '"
    cQry += CRLF + " AND SF2.F2_FILIAL		= SE1.E1_FILORIG"
    cQry += CRLF + " AND SE1.E1_NUM		= SF2.F2_DOC"
    cQry += CRLF + " AND SE1.E1_PREFIXO	= SF2.F2_SERIE"
    //cQry += CRLF + " AND SE1.E1_CLIENTE	= SF2.F2_CLIENTE"
    //cQry += CRLF + " AND SE1.E1_LOJA		= SF2.F2_LOJA"

    cQry += CRLF + " LEFT JOIN "+RetSqlName("SA1")+" SA1"
    cQry += CRLF + " ON SA1.D_E_L_E_T_ = ' '"
    cQry += CRLF + " AND SA1.A1_FILIAL		= '"+xFilial("SA1")+"'"
    cQry += CRLF + " AND SA1.A1_COD		= SE1.E1_CLIENTE"
    cQry += CRLF + " AND SA1.A1_LOJA		= SE1.E1_LOJA"

    cQry += CRLF + " LEFT JOIN "+RetSqlName("SD2")+" SD2"
    cQry += CRLF + " ON SD2.D_E_L_E_T_ = ' '"
    cQry += CRLF + " AND SD2.D2_FILIAL		= SF2.F2_FILIAL "
    cQry += CRLF + " AND SF2.F2_DOC		= SD2.D2_DOC"
    cQry += CRLF + " AND SF2.F2_SERIE		= SD2.D2_SERIE"
    cQry += CRLF + " AND SF2.F2_CLIENTE	= SD2.D2_CLIENTE"
    cQry += CRLF + " AND SF2.F2_LOJA		= SD2.D2_LOJA"

    If !lFatConv // Diferente de conveniência
        cQry += CRLF + " LEFT JOIN "+RetSqlName("UIC")+" UIC"
        cQry += CRLF + " ON UIC.D_E_L_E_T_ = ' '"
        cQry += CRLF + " AND SE1.E1_FILORIG || SE1.E1_PREFIXO || SE1.E1_NUM	= UIC_FILIAL || UIC_AMB || UIC_CODIGO"
    EndIf

    cQry += CRLF + " INNER JOIN "+RetSqlName("FI7")+" FI7	ON SE1.E1_PREFIXO = FI7.FI7_PRFORI"
    cQry += CRLF + " AND SE1.E1_NUM 		= FI7.FI7_NUMORI"
    cQry += CRLF + " AND SE1.E1_PARCELA 	= FI7.FI7_PARORI"
    cQry += CRLF + " AND SE1.E1_TIPO 		= FI7.FI7_TIPORI"
    cQry += CRLF + " AND SE1.E1_CLIENTE 	= FI7.FI7_CLIORI"
    cQry += CRLF + " AND SE1.E1_LOJA 		= FI7.FI7_LOJORI"
    cQry += CRLF + " AND FI7.FI7_PRFDES	= '"+_aFat[4]+"'"
    cQry += CRLF + " AND FI7.FI7_NUMDES	= '"+_aFat[1]+"'"
    cQry += CRLF + " AND FI7.FI7_PARDES	= '"+_aFat[5]+"'"
    cQry += CRLF + " AND FI7.FI7_TIPDES	= '"+_aFat[6]+"'"
    cQry += CRLF + " AND FI7.FI7_CLIDES	= '"+_aFat[2]+"'"
    cQry += CRLF + " AND FI7.FI7_LOJDES	= '"+_aFat[3]+"'"
    cQry += CRLF + " AND FI7.D_E_L_E_T_ = ' '"
    cQry += CRLF + " AND FI7.FI7_FILIAL	= '"+xFilial("FI7")+"'"

    If !lFatConv // Diferente de conveniência

        cQry += CRLF + " LEFT JOIN "+RetSqlName("U57")+" U57" 	
        cQry += CRLF + " ON SE1.E1_XCODBAR		= U57.U57_PREFIX+U57.U57_CODIGO+U57.U57_PARCEL"
        cQry += CRLF + " AND U57.D_E_L_E_T_ = ' '"
        cQry += CRLF + " AND U57.U57_FILIAL	= '"+xFilial("U57")+"'"

        cQry += CRLF + " LEFT JOIN "+RetSqlName("SL1")+" SL1 	ON SE1.E1_PREFIXO	= SL1.L1_SERIE"
        cQry += CRLF + " AND SE1.E1_NUM 	= SL1.L1_DOC"
        cQry += CRLF + " AND SE1.E1_CLIENTE = SL1.L1_CLIENTE"
        cQry += CRLF + " AND SE1.E1_LOJA 	= SL1.L1_LOJA"
        cQry += CRLF + " AND SL1.L1_SITUA 	= 'OK'"
        cQry += CRLF + " AND SL1.D_E_L_E_T_ = ' '"
        cQry += CRLF + " AND SL1.L1_FILIAL	= SE1.E1_FILORIG "
    EndIf

    cQry += CRLF + " WHERE SE1.D_E_L_E_T_ = ' '"
    cQry += CRLF + " AND SE1.E1_FILIAL		= '"+xFilial("SE1",cFilFat)+"'"

    /*If !lFatConv // Diferente de conveniência
        cQry += CRLF + " GROUP BY SE1.E1_TIPO, SE1.E1_NUM, SE1.E1_NUMCART, SE1.E1_PARCELA, SE1.E1_EMISSAO, SE1.E1_XPLACA, SL1.L1_ODOMETR, SL1.L1_NOMMOTO, " + Iif(SL1->(FieldPos("L1_CGCMOTO"))>0,"SL1.L1_CGCMOTO","SL1.L1_CGCCLI") + ","
        cQry += CRLF + " U57.U57_MOTIVO, SE1.E1_VALOR, SE1.E1_VLRREAL, SE1.E1_PREFIXO, SE1.E1_CLIENTE, SE1.E1_LOJA, UIC.UIC_PLACA, UIC.UIC_MOTORI, "
        cQry += CRLF + " SA1.A1_NREDUZ, SA1.A1_EST, SA1.A1_MUN "
    Else
        cQry += " GROUP BY SE1.E1_TIPO, SE1.E1_NUM,SE1.E1_PARCELA, SE1.E1_EMISSAO, "
        cQry += " SE1.E1_VALOR, SE1.E1_VLRREAL, SE1.E1_PREFIXO, SE1.E1_CLIENTE, SE1.E1_LOJA, "
        cQry += " SA1.A1_NREDUZ, SA1.A1_EST, SA1.A1_MUN "
    EndIf*/

    If !lFatConv // Diferente de conveniência

        DbSelectArea("SA1")
        SA1->(DbSetOrder(1)) //A1_FILIAL+A1_COD+A1_LOJA

        If SA1->(DbSeek(xFilial("SA1")+_aFat[2]+_aFat[3]))
            If SA1->A1_XORDFAT == "P"//Ordenação por placa
                cQry += CRLF + " ORDER BY E1_XPLACA,E1_EMISSAO, E1_NUM, E1_PREFIXO, E1_PARCELA, SD2.D2_ITEM"
            Else //Ordenação por data emissao
                cQry += CRLF + " ORDER BY E1_EMISSAO,E1_XPLACA, E1_NUM, E1_PREFIXO, E1_PARCELA, SD2.D2_ITEM"
            Endif
        Else
            cQry += CRLF + " ORDER BY E1_EMISSAO"
        Endif
    Else
        cQry += CRLF + " ORDER BY E1_EMISSAO"
    EndIf

    cQry := ChangeQuery(cQry)
    //MemoWrite("c:\temp\TPIMPFAT_itens.txt",cQry)
    TcQuery cQry NEW Alias "QRYITENS"

    //Verfica se há formas de pagamento OU motivos de saque distintos entre os itens
    While QRYITENS->(!EOF())

        If !lFatConv // Diferente de conveniência

            If Empty(cFpg)
                cFpg :=  QRYITENS->E1_TIPO
            Else
                If cFpg <> QRYITENS->E1_TIPO
                    lDifFpg := .T.
                Endif
            Endif

            If Empty(cMotSaq)
                cMotSaq :=  QRYITENS->U57_MOTIVO
            Else
                If cMotSaq <> QRYITENS->U57_MOTIVO
                    lDifMotSaq := .T.
                Endif
            Endif

            If QRYITENS->E1_TIPO == "VLS" //Vale serviço

                AAdd(aItens,{QRYITENS->E1_NUM,;		//1
                            QRYITENS->E1_PARCELA,;	//2
                            QRYITENS->E1_EMISSAO,;	//3
                            QRYITENS->UIC_PLACA,;	//4
                            Posicione("DA4",1,xFilial("DA4",QRYITENS->E1_FILORIG)+QRYITENS->UIC_MOTORI,"DA4_NOME"),;	//5
                            1,;						//6
                            0,;						//7
                            "",;					//8
                            "",;					//9
                            "",;					//10
                            "",;					//11
                            IIF(QRYITENS->E1_VLRREAL > 0 .And. QRYITENS->E1_VLRREAL <> QRYITENS->E1_VALOR,QRYITENS->E1_VLRREAL,QRYITENS->E1_VALOR),;	//12
                            QRYITENS->E1_TIPO,;		//13
                            QRYITENS->E1_NUMCART,; //14
                            QRYITENS->A1_NREDUZ,; //15
                            QRYITENS->A1_EST,; //16
                            QRYITENS->A1_MUN,; //17
                            QRYITENS->E1_FILORIG,; //18
                            Posicione("SB1",1,xFilial("SB1",QRYITENS->E1_FILORIG)+QRYITENS->UIC_PRODUT,"B1_DESC"),; //19
                            QRYITENS->UIC_PRCPRO,; //20
                            "",; //21
                            QRYITENS->E1_PREFIXO,; //22
                            "-",; //23
						    0 }) //24

            ElseIf Alltrim(QRYITENS->E1_TIPO) == "RP" .And. QRYITENS->E1_PREFIXO == "RPS" //Requisição pós-paga

                AAdd(aItens,{QRYITENS->E1_NUM,;		//1
                            QRYITENS->E1_PARCELA,;	//2
                            QRYITENS->E1_EMISSAO,;	//3
                            QRYITENS->E1_XPLACA,;	//4
                            Posicione("DA4",3,xFilial("DA4",QRYITENS->E1_FILORIG)+QRYITENS->E1_XMOTOR,"DA4_NOME"),;	//5
                            QRYITENS->QTD,;			//6
                            0,;						//7
                            "",;					//8  QRYITENS->U57_REQUIS
                            "",;					//9
                            "",;					//10
                            QRYITENS->U57_MOTIVO,;	//11
                            IIF(QRYITENS->E1_VLRREAL > 0 .And. QRYITENS->E1_VLRREAL <> QRYITENS->E1_VALOR,QRYITENS->E1_VLRREAL,QRYITENS->E1_VALOR),;	//12
                            QRYITENS->E1_TIPO,;		//13
                            QRYITENS->E1_NUMCART,; //14
                            QRYITENS->A1_NREDUZ,; //15
                            QRYITENS->A1_EST,; //16
                            QRYITENS->A1_MUN,; //17
                            QRYITENS->E1_FILORIG,; //18
                            "SAQUE - " + Posicione("SX5",1,xFilial("SX5",QRYITENS->E1_FILORIG)+"UX"+QRYITENS->U57_MOTIVO,"X5_DESCRI") ,; //19
                            QRYITENS->D2_PRCVEN,; //20
                            QRYITENS->D2_ITEM,; //21
                            QRYITENS->E1_PREFIXO,; //22
                            "-",; //23
						    0 }) //24

            Else //Vendas
                lHasVend := .T. //tem venda

                if !lHasAbast
                    lHasAbast := !empty(Posicione("MHZ",3,xFilial("MHZ")+QRYITENS->PROD,"MHZ_CODTAN"))
                endif

                AAdd(aItens,{QRYITENS->E1_NUM,;		//1
                            QRYITENS->E1_PARCELA,;	//2
                            QRYITENS->E1_EMISSAO,;	//3
                            QRYITENS->E1_XPLACA,;	//4
                            QRYITENS->L1_NOMMOTO,;	//5
                            QRYITENS->QTD,;			//6
                            QRYITENS->L1_ODOMETR,;	//7
                            "",;	//8  QRYITENS->U67_REQUIS
                            "",;					//9
                            "",;					//10
                            QRYITENS->U57_MOTIVO,;	//11
                            QRYITENS->E1_VALOR,;	//12
                            QRYITENS->E1_TIPO,;		//13
                            QRYITENS->E1_NUMCART,; //14
                            QRYITENS->A1_NREDUZ,; //15
                            QRYITENS->A1_EST,; //16
                            QRYITENS->A1_MUN,; //17
                            QRYITENS->E1_FILORIG,; //18
                            Posicione("SB1",1,xFilial("SB1",QRYITENS->E1_FILORIG)+QRYITENS->PROD,"B1_DESC"),; //19
                            QRYITENS->D2_PRCVEN,; //20
                            QRYITENS->D2_ITEM,; //21
                            QRYITENS->E1_PREFIXO,; //22
                            QRYITENS->L1_NUM,; //23
						    QRYITENS->RECSD2 }) //24
            Endif
        Else

            AAdd(aItens,{QRYITENS->E1_NUM,;		//1
                            QRYITENS->E1_PARCELA,;	//2
                            QRYITENS->E1_EMISSAO,;	//3
                            "",;					//4
                            "",;					//5
                            QRYITENS->QTD,;			//6
                            "",;					//7
                            "",;					//8
                            "",;					//9
                            "",;					//10
                            "",;					//11
                            QRYITENS->E1_VALOR,;	//12
                            QRYITENS->E1_TIPO,;		//13
                            "",;					//14
                            QRYITENS->A1_NREDUZ,; //15
                            QRYITENS->A1_EST,; //16
                            QRYITENS->A1_MUN,; //17
                            QRYITENS->E1_FILORIG,; //18
                            QRYITENS->PROD,; //19
                            QRYITENS->D2_PRCVEN,; //20
                            QRYITENS->D2_ITEM,; //21
                            QRYITENS->E1_PREFIXO,; //22
                            "-",; //23
						    QRYITENS->RECSD2 }) //24
        EndIf

        QRYITENS->(dbSkip())
    EndDo

    If !lFatConv // Diferente de conveniência
        //Ordena conforme subagrupamento
        If cSubAgrup == "F" .And. lDifFpg
            ASort(aItens,,,{|x,y| x[13]+x[22]+x[1]+x[2]+x[21] > y[13]+y[22]+y[1]+y[2]+y[21]})
        Endif

        If cSubAgrup == "M" .And. lDifMotSaq
            ASort(aItens,,,{|x,y| x[11] > y[11]})
        Endif
    EndIf

    DbSelectArea("SX5")
    SX5->(DbSetOrder(1)) //X5_FILIAL+X5_TABELA+X5_CHAVE

    cFpg 	:= ""
    cMotSaq	:= ""
    cChavItem := ""
    nQtdLin := len(aItens)
    SL2->(DbSetOrder(1)) //L2_FILIAL+L2_NUM+L2_ITEM+L2_PRODUTO

    aClass := {"data_item_center","data_item_center","data_item_center","data_item_center","data_item","data_item","data_item_center_number","data_item_center_number","data_item_center","data_item_right","data_item_right"}
    aColspan := {2,0,0,0,0,3,0,0,0,0,2}
    for nX := 1 to nQtdLin

        if SL2->(DbSeek(aItens[nX][18]+aItens[nX][23]+aItens[nX][21]))
            nValDesc := SL2->(L2_DESCPRO + L2_VALDESC + L2_DESCORC)
        endif
        
        aContent := {}

        if cChavItem <> aItens[nX][1]+aItens[nX][2]+aItens[nX][22]

            If AllTrim(aItens[nX][13]) == "CF" .and. !Empty(aItens[nX][14]) //Carta Frete
                aadd(aContent, AllTrim(aItens[nX][14])) //titulo
            ElseIf AllTrim(aItens[nX][13]) == "RP" //Requisição
                aadd(aContent, AllTrim(aItens[nX][1]) + "/" + aItens[nX][2]) //titulo
            ElseIf AllTrim(aItens[nX][13]) == "VLS" //Vale Serviço
                aadd(aContent, AllTrim(aItens[nX][1]) + "/" + AllTrim(aItens[nX][13])) //titulo
            Else
                aadd(aContent, AllTrim(aItens[nX][1]) + "/" + aItens[nX][2]) //titulo
            Endif
            
            aadd(aContent, aItens[nX][18]) //filial
            aadd(aContent, DToC(SToD(aItens[nX][3]))) //emissao

            If !lFatConv // Diferente de conveniência
                aadd(aContent, Transform(aItens[nX][4],"@!R NNN-9N99")) //placa
                aadd(aContent, aItens[nX][5] ) //motorista
            else
                aadd(aContent, "") //placa
                aadd(aContent, "") //motorista
            EndIf
            
        else
            aadd(aContent, "") //titulo
            aadd(aContent, "") //filial
            aadd(aContent, "") //emissao
            aadd(aContent, "") //placa
            aadd(aContent, "") //motorista
        endif

        aadd(aContent, Alltrim(aItens[nX][19])+iif(aScan(aRecSD2, aItens[nX][24])==0,""," *") ) //item
        aadd(aContent, Alltrim(Transform(aItens[nX][6],"@E 99999999.99"))) //qtde
        aadd(aContent, Alltrim(Transform(aItens[nX][20],"@E 99999999.999"))) //vlr unit

        if aScan(aRecSD2, aItens[nX][24]) == 0 //se recno do SD2 ainda nao somou
		    nTotQtd += aItens[nX][6]
            aadd(aRecSD2, aItens[nX][24])
        else
            lDuplSD2 := .T.
        endif
        
        if cChavItem <> aItens[nX][1]+aItens[nX][2]+aItens[nX][22]
            aadd(aContent, Alltrim(Transform(aItens[nX][7],"@E 99,999,999,999"))) //km
        else
            aadd(aContent, "") //km
        endif

        aadd(aContent, Alltrim(Transform(nValDesc,"@E 9,999,999,999,999.99"))) //desconto

        if cChavItem <> aItens[nX][1]+aItens[nX][2]+aItens[nX][22]
            aadd(aContent, Alltrim(Transform(aItens[nX][12],"@E 9,999,999,999,999.99"))) //vlr total

            nSubVlr	+= aItens[nX][12]
            nTotVlr	+= aItens[nX][12]
        else
            aadd(aContent, "") //vlr total
        endif

        cHtml += DoPrintLin(,,aClass,aColspan,aContent)

        //numero+prefixo
	    cChavItem := aItens[nX][1]+aItens[nX][2]+aItens[nX][22]

        If cSubAgrup == "F" .Or. cSubAgrup == "M"
			cHtml += ImpSubAgrup(aItens, nX, @cFpg, lDifFpg, @cMotSaq, lDifMotSaq, @nSubVlr)
		Endif

    next nX

    If Select("QRYITENS") > 0
        QRYITENS->(dbCloseArea())
    Endif

    //tratativa para ter no minimo X linhas de itens, completa com linhas em branco
    if nQtdLin < nQtdMinLin
        if nQtdLin == 0
            nQtdLin := 1
        endif
        aClass := {"data_item","data_item","data_item","data_item","data_item","data_item","data_item","data_item","data_item","data_item","data_item"}
        aColspan := {2,0,0,0,0,3,0,0,0,0,2}
        for nX := nQtdLin to nQtdMinLin
            cHtml += DoPrintLin(,,aClass,aColspan)
        next nX
    endif

    //ajusto colocando o 3D após os caracteres =
    //cHtml := StrTran(cHtml,'="','=3D"')

    fWrite( nH, cHtml)

Return

Static Function DoCompItens(nH, _aFat)

    Local cHtml := ''
    Local aClass, aColspan, aContent
    Local aVlr := {}
    Local nI

    aClass := {"empty_tl","empty_t","empty_t","empty_t","empty_t","empty_t","empty_t","empty_t","empty_t","empty_t","empty_t","empty_t","empty_t","empty_t","empty_tr"}
    cHtml += DoPrintLin(,,aClass)

    aClass := {"empty_l","tx10","tx8","","tx11b","tx11b_ar","","tx11b","","tx11b_ar","empty_r"}
    aColspan := {0,2,4,0,0,0,0,0,0,0,0}
    aContent := {"","Sequência fatura","","","","","","Total Faturado:","",Transform(nTotVlr,"@E 9,999,999,999,999.99"),""}
    if lHasVend
        If !lFatConv .AND. lHasAbast // Diferente de conveniência
            aContent[5] := "Total Litros:"
        Else
            aContent[5] := "Quant. Total:"
        EndIf
        aContent[6] := Transform(nTotQtd,"@E 99999999.99")

        if lDuplSD2
            aContent[3] := "* Item já listado em outro titulo, por pertercer a mesma venda. Portanto a quantidade não será somada no total."
        endif
    endif
    cHtml += DoPrintLin(iif(!empty(aContent[3]),"35",Nil),,aClass,aColspan,aContent)

    aClass := {"empty_l","tx11b","","","","","","","","","tx11b","","tx11b_ar","empty_r"}
    aColspan := {0,2,0,0,0,0,0,0,0,0,0,0,0,0}
    aContent := {"",cFil + _aFat[1],"","","","","","","","","","","",""}
    //Fatura Flexível
    If nVlrAcres > 0 .Or. nVlrDecres > 0
        If nVlrAcres > 0
            aContent[11] := "Acréscimo:"
            aContent[13] := Transform(nVlrAcres,"@E 9,999,999,999,999.99")

            If nVlrDecres > 0
                cHtml += DoPrintLin(,,aClass,aColspan,aContent)
                aContent[2] := ""
                aContent[11] := "Desconto:"
                aContent[13] := Transform(nVlrDecres,"@E 9,999,999,999,999.99")
            Endif
        ElseIf nVlrDecres > 0
            aContent[11] := "Desconto:"
            aContent[13] := Transform(nVlrDecres,"@E 9,999,999,999,999.99")
        Endif
    Endif
    cHtml += DoPrintLin(,,aClass,aColspan,aContent)

    //linha em branco
    aClass := {"empty_l","","","","","","","","","","","","","","empty_r"}
    cHtml += DoPrintLin(,,aClass)

    aClass := {"empty_l","tx10","","","","","","empty_r"}
    aColspan := {0,8,0,0,0,0,0,0}
    aContent := {"","Valor por extenso","","","","","",""}
    cHtml += DoPrintLin(,,aClass,aColspan,aContent)

    aClass := {"empty_l","tx11b","","","","","","empty_r"}
    aColspan := {0,8,0,0,0,0,0,0}
    aContent := {"","","","","","","",""}
    aVlr := U_UQuebTxt(Extenso(nTotVlr + nVlrAcres - nVlrDecres),80)
    For nI := 1 To Len(aVlr)
        aContent[2] := aVlr[nI] + Space(1) + Replicate("#",70 - Len(aVlr[nI]))
        cHtml += DoPrintLin(,,aClass,aColspan,aContent)
    Next

    aClass := {"empty_l","","","","","","","","","","","title_4","","title_4_r","empty_r"}
    aContent := {"","","","","","","","","","","","Total a Pagar:","",Transform(nTotVlr + nVlrAcres - nVlrDecres,"@E 9,999,999,999,999.99"),""}
    cHtml += DoPrintLin("26",,aClass,,aContent)
    
    aClass := {"empty_bl","empty_b","empty_b","empty_b","empty_b","empty_b","empty_b","empty_b","empty_b","empty_b","empty_b","empty_b","empty_b","empty_b","empty_br"}
    cHtml += DoPrintLin(,,aClass)

    //linha em branco separadora de sessao
    cHtml += DoPrintLin("10")
    
    //ajusto colocando o 3D após os caracteres =
    //cHtml := StrTran(cHtml,'="','=3D"')

    fWrite( nH, cHtml)

Return

Static Function DoDadosFil(nH, _aFat, cObsManual)

    Local nI
    Local cHtml := ''
    Local aClass, aColspan, aContent
    Local aEmails	:= StrTokArr(SuperGetMv("MV_XMAILFT",.F.,"COBRANCA@XXXXXXXX.COM.BR/FATURAMENTO@XXXXXXXX.COM.BR"),"/")
    Local cObs		:= SuperGetMv("MV_XOBSFAT",.F.,"") + Space(1) + AllTrim(cObsManual)
    Local cGerente

    aClass := {"empty_tl","empty_t","empty_t","empty_t","empty_t","empty_t","empty_t","empty_t","empty_t","empty_t","empty_t","empty_t","empty_t","empty_t","empty_tr"}
    cHtml += DoPrintLin(,,aClass)

    dbSelectArea("SM0")
    SM0->(dbSetOrder(1))
    SM0->(dbSeek(cEmpAnt+cFil))
    if SM0->(Eof())
        SM0->(DbSeek(cEmpAnt+cFilAnt))
    endif

    aClass := {"empty_l","tx10","tx11b","tx10","tx11b","empty_r"}
    aColspan := {0,2,5,0,5,0}
    aContent := {"","Razão Social:",SM0->M0_NOMECOM,"Endereço:",SM0->M0_ENDCOB,""}
    cHtml += DoPrintLin(,,aClass,aColspan,aContent)

    aContent := {"","Cidade:",SM0->M0_CIDCOB,"CEP:",Transform(SM0->M0_CEPCOB,"@R 99999-999"),""}
    cHtml += DoPrintLin(,,aClass,aColspan,aContent)

    aContent := {"","CNPJ:",Transform(SM0->M0_CGC,"@R 99.999.999/9999-99"),"Insc. Est.:",SM0->M0_INSC + "&nbsp;",""}
    cHtml += DoPrintLin(,,aClass,aColspan,aContent)

    aContent := {"","Fone Escritório Central:",SM0->M0_TEL,"E-mail:",aEmails[1],""}
    cHtml += DoPrintLin(,,aClass,aColspan,aContent)

    aContent := {"","Fone / Fax Posto:",SM0->M0_TEL,"",iif(len(aEmails)>=2,aEmails[2],""),""}
    cHtml += DoPrintLin(,,aClass,aColspan,aContent)

    DbSelectArea("SA1")
    SA1->(DbSetOrder(1)) //A1_FILIAL+A1_COD+A1_LOJA
    SA1->(DbSeek(xFilial("SA1")+_aFat[2]+_aFat[3]))
    cGerente := Posicione("SU7",1,xFilial("SU7")+SA1->A1_XOPCOBR,"U7_NOME")
    If !Empty(cGerente) .OR. len(aEmails)>=3
        aContent := {"","","","",iif(len(aEmails)>=3,aEmails[3],""),""}
        if !Empty(cGerente)
            aContent[2] := "Gerente Recebimento:"
            aContent[3] := Upper(cGerente)
        endif
        cHtml += DoPrintLin(,,aClass,aColspan,aContent)
    Endif

    For nI := 4 To Len(aEmails)
        aContent := {"","","","",iif(len(aEmails)>=3,aEmails[3],""),""}
        cHtml += DoPrintLin(,,aClass,aColspan,aContent)
    Next

    If !Empty(cObs)
        //linha em branco
        aClass := {"empty_l","","","","","","","","","","","","","","empty_r"}
        cHtml += DoPrintLin("15",,aClass)

        aClass := {"empty_l","tx11b","empty_r"}
        aColspan := {0,13,0}
        aContent := {"",Upper(cObs),""}
        cHtml += DoPrintLin(,,aClass,aColspan,aContent)
    Endif    

    aClass := {"empty_bl","empty_b","empty_b","empty_b","empty_b","empty_b","empty_b","empty_b","empty_b","empty_b","empty_b","empty_b","empty_b","empty_b","empty_br"}
    cHtml += DoPrintLin(,,aClass)

    //linha em branco separadora de sessao
    cHtml += DoPrintLin("10")
    
    //ajusto colocando o 3D após os caracteres =
    //cHtml := StrTran(cHtml,'="','=3D"')

    fWrite( nH, cHtml)

Return

Static Function DoResumo(nH, _aFat)

    Local cHtml := ''
    Local nRecSD2	:= 0
    Local aClass, aColspan, aContent
    Local cQry 		:= ""

    If Select("QRYRES") > 0
        QRYRES->(dbCloseArea())
    Endif

    cQry := "SELECT SB1.B1_COD, SB1.B1_DESC, SD2.D2_PRCVEN AS VLR, SD2.D2_QUANT AS QTD,  SD2.D2_TOTAL AS TOTAL, SD2.R_E_C_N_O_ RECSD2"
    cQry += CRLF + " FROM "+RetSqlName("SE1")+" SE1 INNER JOIN "+RetSqlName("SF2")+" SF2 ON SE1.E1_NUM	= SF2.F2_DOC
    cQry += CRLF + " AND SE1.E1_PREFIXO	= SF2.F2_SERIE"
    //cQry += CRLF + " AND SE1.E1_CLIENTE	= SF2.F2_CLIENTE"
    //cQry += CRLF + " AND SE1.E1_LOJA		= SF2.F2_LOJA"
    cQry += CRLF + " AND SF2.F2_FILIAL		= SE1.E1_FILORIG"
    cQry += CRLF + " AND SF2.D_E_L_E_T_ 	= ' '"

    cQry += CRLF + " INNER JOIN "+RetSqlName("SD2")+" SD2 ON SF2.F2_DOC = SD2.D2_DOC"
    cQry += CRLF + " AND SF2.F2_SERIE		= SD2.D2_SERIE"
    cQry += CRLF + " AND SF2.F2_CLIENTE		= SD2.D2_CLIENTE"
    cQry += CRLF + " AND SF2.F2_LOJA		= SD2.D2_LOJA"
    cQry += CRLF + " AND SD2.D_E_L_E_T_ 	= ' '"
    cQry += CRLF + " AND SD2.D2_FILIAL		= SF2.F2_FILIAL"

    cQry += CRLF + " INNER JOIN "+RetSqlName("SB1")+" SB1 ON SD2.D2_COD = SB1.B1_COD"
    cQry += CRLF + " AND SB1.D_E_L_E_T_ = ' '"
    cQry += CRLF + " AND SB1.B1_FILIAL		= '"+xFilial("SB1",cFilFat)+"'"

    cQry += CRLF + " INNER JOIN "+RetSqlName("FI7")+" FI7	ON SE1.E1_PREFIXO = FI7.FI7_PRFORI"
    cQry += CRLF + " AND SE1.E1_NUM 		= FI7.FI7_NUMORI"
    cQry += CRLF + " AND SE1.E1_PARCELA 	= FI7.FI7_PARORI"
    cQry += CRLF + " AND SE1.E1_TIPO 		= FI7.FI7_TIPORI"
    cQry += CRLF + " AND SE1.E1_CLIENTE 	= FI7.FI7_CLIORI"
    cQry += CRLF + " AND SE1.E1_LOJA 		= FI7.FI7_LOJORI"
    cQry += CRLF + " AND FI7.FI7_PRFDES		= '"+_aFat[4]+"'"
    cQry += CRLF + " AND FI7.FI7_NUMDES		= '"+_aFat[1]+"'"
    cQry += CRLF + " AND FI7.FI7_PARDES		= '"+_aFat[5]+"'"
    cQry += CRLF + " AND FI7.FI7_TIPDES		= '"+_aFat[6]+"'"
    cQry += CRLF + " AND FI7.FI7_CLIDES		= '"+_aFat[2]+"'"
    cQry += CRLF + " AND FI7.FI7_LOJDES		= '"+_aFat[3]+"'"
    cQry += CRLF + " AND FI7.D_E_L_E_T_ 	= ' '"
    cQry += CRLF + " AND FI7.FI7_FILIAL		= '"+xFilial("FI7",cFilFat)+"'"

    cQry += CRLF + " WHERE SE1.D_E_L_E_T_ = ' '"
    cQry += CRLF + " AND SE1.E1_FILIAL		= '"+xFilial("SE1",cFilFat)+"'"
    cQry += CRLF + " ORDER BY SB1.B1_COD, SB1.B1_DESC, SD2.D2_PRCVEN, SD2.R_E_C_N_O_"

    cQry := ChangeQuery(cQry)
    //MemoWrite("c:\temp\RFATE013.txt",cQry)
    TcQuery cQry NEW Alias "QRYRES"

    if QRYRES->(EOF())
        If Select("QRYRES") > 0
            QRYRES->(dbCloseArea())
        Endif
        Return
    endif

    //linha em branco
    aClass := {"","title_4","","","","","","","","","","","","",""}
    aContent := {"","Resumo","","","","","","","","","","","","",""}
    cHtml += DoPrintLin(,,aClass,,aContent)

    aClass := {"head_item","head_item","head_item","head_item"}
    aColspan := {6,3,3,3}
    aContent := {"Item (produto/serviço)","Qtde.","R$ Unitario","R$ Total"}
    cHtml += DoPrintLin(,,aClass,aColspan,aContent)

    //ajusto colocando o 3D após os caracteres =
    //cHtml := StrTran(cHtml,'="','=3D"')

    fWrite( nH, cHtml)

    //itens
    cHtml := ""
    aClass := {"data_item","data_item_center_number","data_item_center_number","data_item_center_number"}
    aColspan := {6,3,3,3}
    While QRYRES->(!EOF())
        if nRecSD2 == QRYRES->RECSD2
            QRYRES->(DbSkip())
            LOOP
        endif

        aContent := {QRYRES->B1_DESC,;
                    Transform(QRYRES->QTD,"@E 99999999.99"),;
                    Transform(QRYRES->TOTAL / QRYRES->QTD,"@E 999,999,999.999"),;
                    Transform(QRYRES->TOTAL,"@E 999,999,999.99")}
        
        cHtml += DoPrintLin(,,aClass,aColspan,aContent)

        nRecSD2 := QRYRES->RECSD2

        QRYRES->(DbSkip())
    EndDo

    If Select("QRYRES") > 0
		QRYRES->(dbCloseArea())
	Endif

    aClass := {"empty_t","empty_t","empty_t","empty_t"}
    cHtml += DoPrintLin("10",,aClass,aColspan)

    //ajusto colocando o 3D após os caracteres =
    //cHtml := StrTran(cHtml,'="','=3D"')

    fWrite( nH, cHtml)

Return

//Fecha arquivo com rodape
Static Function DoFooter(nH, lImpTextos)

    Local cHtml := ""
    Local cNomEmp := Alltrim(SM0->M0_FULNAME) //Alltrim(SuperGetMv("MV_XNOMEMP",.F.,SM0->M0_NOMECOM))
    Local aClass, aColspan, aContent

    if lImpTextos
        
        aClass := {"","tx10","tx10","tx10_ar",""}
        aColspan := {0,3,5,5,0}
        aContent := {"","Cliente optante por fatura solidária:",IIF(!Empty(cFatSol),cFatSol,"Indefinido"),cNomEmp,""}
        cHtml += DoPrintLin(,,aClass,aColspan,aContent)

        aClass := {"","tx10","tx10","tx10_ar",""}
        aColspan := {0,3,5,5,0}
        aContent := {"","Classe:",cClasse,"Protheus - TOTVS Goiás",""}
        cHtml += DoPrintLin(,,aClass,aColspan,aContent)

        aClass := {"","tx10","tx10","tx10_ar",""}
        aColspan := {0,3,5,5,0}
        aContent := {"","Possui DANFE relacionada:",IIF(lDanfe,"Sim","Não"),"",""}
        cHtml += DoPrintLin(,,aClass,aColspan,aContent)

    endif

    cHtml += '</table>' + CRLF
    cHtml += '<body>' + CRLF
    cHtml += '<html>' + CRLF

    //ajusto colocando o 3D após os caracteres =
    //cHtml := StrTran(cHtml,'="','=3D"')

    fWrite( nH, cHtml)

Return

Static Function ImpSubAgrup(aItens, nI, cFpg, lDifFpg, cMotSaq, lDifMotSaq, nSubVlr)

    Local aClass, aColspan, aContent
    Local cHtml := ""

    aClass := {"data_item","data_item","data_item","data_item","data_item","data_tot_left","data_tot_left","data_tot_left","data_tot_left","data_tot_left","data_tot_right"}
    aColspan := {2,0,0,0,0,3,0,0,0,0,2}

	If cSubAgrup == "F" .And. lDifFpg
		If Empty(cFpg)
			cFpg := aItens[nI][13]
		Else
			If nI + 1 <= Len(aItens)
				If cFpg <> aItens[nI + 1][13]
                    
                    aContent := {"","","","","","","Total " + UPPER(Alltrim(Posicione("SX5",1,xFilial("SX5")+'05'+cFpg,"X5_DESCRI"))),"","","",Alltrim(Transform(nSubVlr,"@E 9,999,999,999,999.99"))}
                    cHtml += DoPrintLin(,,aClass,aColspan,aContent)

					nSubVlr := 0
					cFpg := aItens[nI + 1][13]
				Endif
			Endif
		Endif

	ElseIf cSubAgrup == "M" .And. lDifMotSaq
		If Empty(cMotSaq)

			cMotSaq := aItens[nI][11]
		Else
			If nI + 1 <= Len(aItens)
				If cMotSaq <> aItens[nI + 1][11]

                    aContent := {"","","","","","","Total " + UPPER(Alltrim(Posicione("SX5",1,xFilial("SX5")+"UX"+cMotSaq,"X5_DESCRI"))),"","","",Alltrim(Transform(nSubVlr,"@E 9,999,999,999,999.99"))}
                    cHtml += DoPrintLin(,,aClass,aColspan,aContent)

					nSubVlr := 0
					cMotSaq := aItens[nI + 1][11]
				Endif
			Endif
		Endif
	Endif

	If lDifFpg .Or. lDifMotSaq
		If nI == Len(aItens)
			
            if lDifFpg
                aContent := {"","","","","","","Total " + UPPER(Alltrim(Posicione("SX5",1,xFilial("SX5")+'05'+cFpg,"X5_DESCRI"))),"","","",Alltrim(Transform(nSubVlr,"@E 9,999,999,999,999.99"))}
                cHtml += DoPrintLin(,,aClass,aColspan,aContent)
            else
                aContent := {"","","","","","","Total " + UPPER(Alltrim(Posicione("SX5",1,xFilial("SX5")+"UX"+cMotSaq,"X5_DESCRI"))),"","","",Alltrim(Transform(nSubVlr,"@E 9,999,999,999,999.99"))}
                cHtml += DoPrintLin(,,aClass,aColspan,aContent)
            endif

		Endif
	Endif
	
Return cHtml


Static Function RetDanfe(_aFat)

Local lRet := .F.
Local cQry := ""

If Select("QRYNFCF") > 0
	QRYNFCF->(dbCloseArea())
Endif

cQry := "SELECT SF2.F2_NFCUPOM"
cQry += CRLF + " FROM "+RetSqlName("SE1")+" SE1 INNER JOIN "+RetSqlName("SF2")+" SF2 ON SE1.E1_NUM	= SF2.F2_DOC"
cQry += CRLF + " AND SE1.E1_PREFIXO	= SF2.F2_SERIE"
cQry += CRLF + " AND SE1.E1_CLIENTE	= SF2.F2_CLIENTE"
cQry += CRLF + " AND SE1.E1_LOJA		= SF2.F2_LOJA"
cQry += CRLF + " AND SF2.D_E_L_E_T_ = ' '"
cQry += CRLF + " AND SF2.F2_FILIAL 	= SE1.E1_FILORIG"

cQry += CRLF + " INNER JOIN "+RetSqlName("FI7")+" FI7	ON SE1.E1_PREFIXO = FI7.FI7_PRFORI"
cQry += CRLF + " AND SE1.E1_NUM 		= FI7.FI7_NUMORI"
cQry += CRLF + " AND SE1.E1_PARCELA 	= FI7.FI7_PARORI"
cQry += CRLF + " AND SE1.E1_TIPO 		= FI7.FI7_TIPORI"
cQry += CRLF + " AND SE1.E1_CLIENTE 	= FI7.FI7_CLIORI"
cQry += CRLF + " AND SE1.E1_LOJA 		= FI7.FI7_LOJORI"
cQry += CRLF + " AND FI7.FI7_PRFDES	= '"+_aFat[4]+"'"
cQry += CRLF + " AND FI7.FI7_NUMDES	= '"+_aFat[1]+"'"
cQry += CRLF + " AND FI7.FI7_PARDES	= '"+_aFat[5]+"'"
cQry += CRLF + " AND FI7.FI7_TIPDES	= '"+_aFat[6]+"'"
cQry += CRLF + " AND FI7.FI7_CLIDES	= '"+_aFat[2]+"'"
cQry += CRLF + " AND FI7.FI7_LOJDES	= '"+_aFat[3]+"'"
cQry += CRLF + " AND FI7.D_E_L_E_T_ = ' '"
cQry += CRLF + " AND FI7.FI7_FILIAL 	= '"+xFilial("FI7",cFilFat)+"'"
cQry += CRLF + " WHERE SE1.D_E_L_E_T_ = ' '"
cQry += CRLF + " AND SE1.E1_FILIAL 	= '"+xFilial("SE1",cFilFat)+"'"

cQry += CRLF + " ORDER BY 1"

cQry := ChangeQuery(cQry)
//MemoWrite("c:\temp\RFATE006.txt",cQry)
TcQuery cQry NEW Alias "QRYNFCF"

While QRYNFCF->(!EOF())

	If !Empty(QRYNFCF->F2_NFCUPOM)
		lRet := .T.
		Exit
	Endif

	QRYNFCF->(DbSkip())
EndDo

If Select("QRYNFCF") > 0
	QRYNFCF->(dbCloseArea())
Endif

Return lRet


/*
Descricao:	Cria e Executa, via WaitRun, os Scripts em PowerShell
*/
Static Function PsExecute(cPathFiles, cPsFile, cHtmFile, cExcelFile )

	//Local cPsFile		:= ( CriaTrab( NIL , .F. ) + ".ps1" )
	Local cPsScript		:= ""
	Local cNewPsFile	:= ""
	Local cWaitRunCmd	:= ""

	Local lStatus		:= .F.

    cPsScript 	+= '# -----------------------------------------------------'+ CRLF
	cPsScript 	+= 'function Release-Ref ($ref) {' + CRLF
	cPsScript 	+= '	([System.Runtime.InteropServices.Marshal]::ReleaseComObject(' + CRLF 
	cPsScript 	+= '	[System.__ComObject]$ref) -gt 0)' + CRLF 
	cPsScript 	+= '	[System.GC]::Collect()' + CRLF 
	cPsScript 	+= '	[System.GC]::WaitForPendingFinalizers()' + CRLF 
	cPsScript 	+= '}' + CRLF 
	cPsScript 	+= '# -----------------------------------------------------' + CRLF 
	cPsScript 	+= '$objExcel	= New-Object -Com Excel.Application;' + CRLF
    cPsScript 	+= '$objExcel.Visible		= $False;' + CRLF
    cPsScript 	+= '$objExcel.DisplayAlerts	= $False;' + CRLF
    cPsScript 	+= "$objWorkBook = $objExcel.Workbooks.Open('"+cPathFiles+cHtmFile+"');" + CRLF
    cPsScript 	+= "$objWorkBook.SaveAs('"+cPathFiles+cExcelFile+"', 51); # 51 representa o formato XLSX" + CRLF
    cPsScript 	+= '$objExcel.Quit();' + CRLF
    cPsScript 	+= '$dummy = Release-Ref($objWorkBook)	| Out-Null;' + CRLF
	cPsScript 	+= '$dummy = Release-Ref($objExcel)	| Out-Null;' + CRLF

	cNewPsFile	:= Lower( cPathFiles + cPsFile )
	MemoWrite( cNewPsFile , cPsScript )

	IF ( File( cNewPsFile ) )

		cWaitRunCmd	:= "PowerShell -NonInteractive -WindowStyle Hidden -File " + cNewPsFile + ""

		lStatus := ( WaitRun( cWaitRunCmd , SW_HIDE ) == 0 )

		fErase( cNewPsFile )

        lStatus := File( cPathFiles+cExcelFile )
	EndIF

Return( lStatus )

Static Function DelFiles(cFileMain, cCaminho)

	Local cFile 	:= "" //Arquivi
	Local aFiles 	:= {} //Array de Arquivos
	Local nFiles 	:= 0 //Contador de Arquivos
	Local nC 		:= 0 //Contador

    FErase(cFileMain,,.t.)

    aFiles := Directory(cCaminho+"*.*", "D")
    nFiles := Len(aFiles)

    //Apaga primeiro os arquivos 
    For nC := 1 to nFiles
        cFile := aFiles[nC, 01]
        If cFile <> '.' .AND. cFile <> '..'
            FErase(cCaminho + cFile,,.t.)
        EndIf
    Next

    //apaga depois a pasta
    DirRemove(cCaminho)

Return
