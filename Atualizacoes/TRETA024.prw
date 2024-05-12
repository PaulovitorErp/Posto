#INCLUDE "TOTVS.CH"
#INCLUDE "Protheus.ch"
#INCLUDE "topconn.ch"
#INCLUDE "TBICONN.CH"

#DEFINE cEOL chr(13)+chr(10)

/*/{Protheus.doc} TRETA024
Rotina para fazer negociação de Preços, aplicando acrescimo ou desconto.

@author Totvs GO
@since 17/04/2014
@version 1.0
@return Nulo

@type function
/*/

User Function TRETA024()

	Local cUsrCmp := ""

	//Campos da tela de perguntas
	Private cAdmF := Space (300) //Space(TamSx3("AE_COD")[1])
	Private cCliAte := StrTran(Space(TamSx3("A1_COD")[1])," ","z")
	Private cCliDe := Space(TamSx3("A1_COD")[1])
	Private cEmitenAte := StrTran(Space(TamSx3("A1_COD")[1])," ","z")
	Private cEmitenDe := Space(TamSx3("A1_COD")[1])
	Private cCondPg := space(300) //Space(TamSx3("E4_CODIGO")[1])
	Private nDiasAtr := 0
	Private cRiscoCli := space(300) //Space(TamSx3("A1_XRISCO")[1])
	Private cFormaPg := space(300) //Space(TamSx3("U25_FORPAG")[1])
	Private cGrupCli := space(300) //Space(TamSx3("ACY_GRPVEN")[1])
	Private cClasCli := space(300) //Space(TamSx3("A1_XCLASSE")[1])
	Private cSegCli := space(300) //Space(TamSx3("A1_SATIV1")[1])
	Private cGrupPro := space(300) //Space(TamSx3("BM_GRUPO")[1])
	Private cLojaAte := StrTran(Space(TamSx3("A1_LOJA")[1])," ","z")
	Private cLojaDe := Space(TamSx3("A1_LOJA")[1])
	Private cLojEmiAte := StrTran(Space(TamSx3("A1_LOJA")[1])," ","z")
	Private cLojEmiDe := Space(TamSx3("A1_LOJA")[1])
	Private lMargDAb := .F.
	Private lMargDAc := .F.
	Private lMargMAb := .F.
	Private lMargMAc := .F.
	Private lRepFil := .F.
	Private lExcecao := .F.
	Private nPrecoDe := 0
	Private nPrecoAte := 0
	Private nDesPbDe := -9999999.999
	Private nDesPbAte := 99999999.999
	Private cProdAte := StrTran(Space(TamSx3("B1_COD")[1])," ","z")
	Private cProdDe := Space(TamSx3("B1_COD")[1])
	Private nRentAte := 0
	Private nRentDe := 0
	Private cPadrao := "T"
	Private lWhenRepFil := .T.

	//cadastra rotina para controle de acesso
	U_TRETA37B("UFT002", "ATUALIZAR PREÇOS NEGOCIADOS")

	//verifica se o usuário tem permissão para acesso a rotina
	cUsrCmp := U_VLACESS1("UFT002", RetCodUsr())
	if cUsrCmp == Nil .OR. empty(cUsrCmp)
		Return
	endif

	While .T. //enquanto nao cancelar a rotina

		if DoParam() //Chama a tela de parametros
			TRETA024()
		else
			Exit
		endif

	EndDo

Return

//Processamento da rotina
Static Function TRETA024()

	Local cCadastro := "Atualiza Preço Negociação"
	Local bOk := {|| iif(DoGrava(),oDlg:End(),) }
	Local bCancel := {|| oDlg:End() }

	Private aSize := MsAdvSize() // Retorna a área útil das janelas Protheus
	Private aInfo := {aSize[1], aSize[2], aSize[3], aSize[4], 2, 2}
	Private aPObj := MsObjSize(aInfo, {{ 100, 115, .T., .F.}, { 100, 100, .T., .T.}, { 100, 000, .T., .F.}})
	Private oDlg
	Private aButtons := {}

	// variavel para ordenação de grids
	Private __XVEZ 		:= "0"
	Private __ASC       := .T.

	//Campos dos Grids
	Private oMSNewGe1
	Private aDados1 := {}
	Private aHeader1 := {}
	Private oMSNewGe2
	Private aDados2 := {}
	Private aHeader2 := {}
	Private nMarca  :=  0 //Variavel de controle da função MarcaTodos
	Private __XVEZ	:= "0" //Variavel de controle da função MarcaTodos

	//Campos do cálculo novo preço
	Private _dDtInic  := dDataBase
	Private _cHrInic  := "00:00"
	Private _cTpCalc  := " "
	Private _aTpCalc  := {"1=Preço Fixo","2=Acréscimo","3=Desconto"," "}
	Private _nValAju  := 0
	Private _cTipoAD  := " "
	Private _aTipoAD  := {"1=Percentual","2=Valor"," "}
	Private _cFilDest := space(len(xFilial("U25")))

	lWhenRepFil := .F.

	if lRepFil
		aPObj := MsObjSize(aInfo, {{ 100, 230, .T., .F.}, { 100, 100, .T., .T.}, { 100, 000, .T., .F.}})
	endif

	oDlg := TDialog():New(aSize[7],aSize[1],aSize[6],aSize[5],cCadastro,,,,,,,,,.T.)

	//Parte Superior
	TButton():New( aPObj[1,1], aPObj[1,4]-85, "Buscar Preços Negociados", oDlg, {|| iif(DoParam(),DoFiltro(.T.),) }, 80, 10,,,.F.,.T.,.F.,,.F.,,,.F. )
	oGroup := TGroup():Create(oDlg,aPObj[1,1]+2,aPObj[1,2],aPObj[1,3],aPObj[1,4],'Preços Negociados',,,.T.)

	oMSNewGe1 := fMSNewGe1(oDlg)
	oMSNewGe1:oBrowse:bHeaderClick := {|oBrw,nCol,aDim| if(oMSNewGe1:oBrowse:nColPos<>111 .and. nCol == 1,(MarcaTodos(),oBrw:SetFocus()), if(aHeader1[nCol][8]=="M", IF(oMSNewGe1:LCANEDITLINE,(OBRW:NCOLPOS := NCOL,GETCELLRECT(OBRW,@ADIM),GETDEDITMENU(oMSNewGe1,ADIM)),), if(nCol > 0, U_UOrdGrid(@oMSNewGe1, @nCol), ) ) )}
	bSvblDblClick := oMSNewGe1:oBrowse:bLDblClick
	//oMSNewGe1:oBrowse:bLDblClick := {|| if(oMSNewGe1:oBrowse:nColPos<>1,GdRstDblClick(@oMSNewGe1,@bSvblDblClick),Marcar())}
	oMSNewGe1:oBrowse:bLDblClick := {|| if(oMSNewGe1:oBrowse:nColPos == aScan(aHeader1,{|x| Trim(x[2])=="U25_OBS"}),GdRstDblClick(@oMSNewGe1,@bSvblDblClick),Marcar())}

	aDados1 := oMSNewGe1:aCols //defino aDados1 mesmo que aCols
	DoFiltro(.F.) //faz primeira busca de dados

	if lRepFil

		//Parte Meio
		oGroup := TGroup():Create(oDlg,aPObj[2,1],aPObj[2,2],aPObj[2,3],aPObj[2,4],'Configurar Replicar',,,.T.)

		TSay():New( aPObj[2,1]+8,5,{|| "Data Início" }, oDlg,,,,,,.T.,CLR_BLUE,,50,9 )
		oDtIniTst := TGet():New( aPObj[2,1]+16,5,{|u| iif( PCount()==0,_dDtInic,_dDtInic:= u) },oDlg,50,9,,/*bValid*/,,,,.F.,,.T.,,.F.,{|| .T.},.F.,.F.,/*bChange*/,.F.,.F.,,"U25_DTINIC",,,,.T.,.F.)

		TSay():New( aPObj[2,1]+8,65,{|| "Hora Início" }, oDlg,,,,,,.T.,CLR_BLACK,,50,9 )
		TGet():New( aPObj[2,1]+16,65,{|u| iif( PCount()==0,_cHrInic,_cHrInic:= u) },oDlg,20,9,"99:99",/*bValid*/,,,,.F.,,.T.,,.F.,{|| .T.},.F.,.F.,/*bChange*/,.F.,.F.,,"U25_HRINIC",,,,.T.,.F.)

		TSay():New( aPObj[2,1]+8,105,{|| "Filial Destino" }, oDlg,,,,,,.T.,CLR_BLACK,,50,9 )
		TGet():New( aPObj[2,1]+16,105,{|u| iif( PCount()==0,_cFilDest,_cFilDest:= u) },oDlg,50,9,,/*bValid*/,,,,.F.,,.T.,,.F.,{|| .T.},.F.,.F.,/*bChange*/,.F.,.F.,"XM0","U25_FILIAL",,,,.T.,.F.)

	else

		//Parte Meio
		oGroup := TGroup():Create(oDlg,aPObj[2,1],aPObj[2,2],aPObj[2,1]+30,aPObj[2,4],'Cálculo do Novo Preço',,,.T.)

		TSay():New( aPObj[2,1]+8,5,{|| "Data Início" }, oDlg,,,,,,.T.,CLR_BLUE,,50,9 )
		oDtIniTst := TGet():New( aPObj[2,1]+16,5,{|u| iif( PCount()==0,_dDtInic,_dDtInic:= u) },oDlg,50,9,,/*bValid*/,,,,.F.,,.T.,,.F.,{|| .T.},.F.,.F.,/*bChange*/,.F.,.F.,,"U25_DTINIC",,,,.T.,.F.)

		TSay():New( aPObj[2,1]+8,65,{|| "Hora Início" }, oDlg,,,,,,.T.,CLR_BLACK,,50,9 )
		TGet():New( aPObj[2,1]+16,65,{|u| iif( PCount()==0,_cHrInic,_cHrInic:= u) },oDlg,20,9,"99:99",/*bValid*/,,,,.F.,,.T.,,.F.,{|| .T.},.F.,.F.,/*bChange*/,.F.,.F.,,"U25_HRINIC",,,,.T.,.F.)

		TSay():New( aPObj[2,1]+8,105,{|| "Tipo Cálculo" }, oDlg,,,,,,.T.,CLR_BLUE,,50,9 )
		TComboBox():New(aPObj[2,1]+16, 105, {|u| iif( PCount()==0,_cTpCalc,_cTpCalc:= u) },_aTpCalc, 60, 9, oDlg,,/*bChange*/, {|| iif(_cTpCalc $ "1/ ",(_cTipoAD:=" ",_nValAju:=0,.T.),.T.) }/*bValid*/,,,.T.,,,,{|| .T.},,,,"_cTpCalc")

		TSay():New( aPObj[2,1]+8,175,{|| "Tipo Valor" }, oDlg,,,,,,.T.,CLR_BLACK,,50,9 )
		TComboBox():New(aPObj[2,1]+16, 175, {|u| iif( PCount()==0,_cTipoAD,_cTipoAD:= u) },_aTipoAD, 45, 9, oDlg,,/*bChange*/, /*bValid*/,,,.T.,,,,{|| !(_cTpCalc $ "1/ ")},,,,"_cTipoAD")

		TSay():New( aPObj[2,1]+8,230,{|| "Valor" }, oDlg,,,,,,.T.,CLR_BLUE,,50,9 )
		TGet():New( aPObj[2,1]+16,230,{|u| iif( PCount()==0,_nValAju,_nValAju:= u) },oDlg,70,9,"@E 999,999,999.9999",/*bValid*/,,,,.F.,,.T.,,.F.,{|| !(_cTpCalc $ " ") },.F.,.F.,/*bChange*/,.F.,.F.,,"_nValAju",,,,.T.,.F.)

		TButton():New( aPObj[2,1]+16, 305, "Calcular Preços", oDlg, {|| AddItens() }, 60, 11,,,.F.,.T.,.F.,,.F.,,,.F. )

		//Parte Inferior
		oGroup := TGroup():Create(oDlg,aPObj[2,1]+32,aPObj[2,2],aPObj[2,3],aPObj[2,4],'Novos Preços Negociados',,,.T.)
		oMSNewGe2 := fMSNewGe2(oDlg)
		oMSNewGe2:oBrowse:bHeaderClick := {|oBrw,nCol| if(aHeader2[nCol][8]=="M", IF(oMSNewGe2:LCANEDITLINE,(OBRW:NCOLPOS := NCOL,GETCELLRECT(OBRW,@ADIM),GETDEDITMENU(oMSNewGe2,ADIM)),), if(nCol > 0, U_UOrdGrid(@oMSNewGe2, @nCol), ) ) }

		aDados2 := oMSNewGe2:aCols //defino aDados2 mesmo que aCols

	endif

	Aadd( aButtons, {"Excluir", {|| DoExcluiSel()}, "Excluir Sel.", "Excluir Sel." , {|| .T.}} )

	oDlg:bInit := {|| EnchoiceBar(oDlg, bOk, bCancel,.F.,@aButtons,0,"U25")}
	oDlg:lCentered := .T.
	oDlg:Activate()

Return

/*
_____________________________________________________________________________
¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦
¦¦+-----------------------------------------------------------------------+¦¦
¦¦¦Programa  ¦ fMSNewGe1    ¦ Autor ¦ Totvs          ¦ Data ¦ 15/01/2014  ¦¦¦
¦¦+----------+------------------------------------------------------------¦¦¦
¦¦¦Descriçào ¦ Cria grid da preços negociados							  ¦¦¦
¦¦¦          ¦                                                            ¦¦¦
¦¦+----------+------------------------------------------------------------¦¦¦
¦¦¦Uso       ¦ TOTVS - GO		                                          ¦¦¦
¦¦+-----------------------------------------------------------------------+¦¦
¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦
¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯
*/
Static Function fMSNewGe1(oComp)

	Local nX, aSX3U25
	Local aAlterFields := {}
	Local aTemp := {}

	Aadd(aHeader1,{ '','MARK','@BMP',2,0,'','€€€€€€€€€€€€€€','C','','','',''})  //[1] Mark
	Aadd(aHeader1,{ 'Seq.','SEQ','@!',4,0,'','€€€€€€€€€€€€€€','C','','','',''}) //[2] Seq.
	Aadd(aHeader1,{}) //[3] Cod Prod.
	Aadd(aHeader1,{}) //[4] Desc. Prod.
	Aadd(aHeader1,{}) //[5] Preço Base
	Aadd(aHeader1,{}) //[6] Preço negociado
	Aadd(aHeader1,{}) //[7] Desconto/Acrescimo
	Aadd(aHeader1,{}) //[8] Data Inic
	Aadd(aHeader1,{}) //[9] Hora Inic
	Aadd(aHeader1,{ 'Margem Lucro(%)','PLUCRO','@E 99,999.99',9,2,'','€€€€€€€€€€€€€€','N','','','',''})   //[10] % Lucro
	Aadd(aHeader1,{ 'Rentabilidade(%)','PRENTAB','@E 99,999.99',9,2,'','€€€€€€€€€€€€€€','N','','','',''}) //[11] % Rentab

	// Define field properties
	aSX3U25 := FWSX3Util():GetAllFields( "U25" , .T./*lVirtual*/ )
	If !empty(aSX3U25)
		For nX := 1 to len(aSX3U25)

			If (X3Uso(GetSx3Cache(aSX3U25[nX],"X3_USADO")) .OR. GetSx3Cache(aSX3U25[nX],"X3_BROWSE") == 'S') .and. cNivel>=GetSx3Cache(aSX3U25[nX],"X3_NIVEL")
				aTemp := U_UAHEADER(aSX3U25[nX])

				if alltrim(aSX3U25[nX]) == "U25_PRODUT"
					aHeader1[3] := aTemp
				elseif alltrim(aSX3U25[nX]) == "U25_DESPRO"
					aHeader1[4] := aTemp
				elseif alltrim(aSX3U25[nX]) == "U25_PRCBAS"
					aHeader1[5] := aTemp
				elseif alltrim(aSX3U25[nX]) == "U25_PRCVEN"
					aHeader1[6] := aTemp
				elseif alltrim(aSX3U25[nX]) == "U25_DESPBA"
					aHeader1[7] := aTemp
				elseif alltrim(aSX3U25[nX]) == "U25_DTINIC"
					aHeader1[8] := aTemp
				elseif alltrim(aSX3U25[nX]) == "U25_HRINIC"
					aHeader1[9] := aTemp
				else
					Aadd(aHeader1, aTemp)
				endif
			endif

		next nX
	endif

	//validando posições fixas
	for nX := 1 to 8
		if len(aHeader1[nX]) == 0
			Alert("Campos obrigatorios da rotina não estão configurados corretamente na base SX3.")
			return Nil
		endif
	next nX

Return MsNewGetDados():New( aPObj[1,1]+12,aPObj[1,2]+2,aPObj[1,3]-3,aPObj[1,4]-2,, ;
		"AllwaysTrue", "AllwaysTrue",, aAlterFields,, 9999, "AllwaysTrue", "", "AllwaysTrue", oComp, aHeader1, aDados1)

/*
_____________________________________________________________________________
¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦
¦¦+-----------------------------------------------------------------------+¦¦
¦¦¦Programa  ¦ DoFiltro    ¦ Autor ¦ Totvs GO         ¦ Data ¦ 25/04/2014 ¦¦¦
¦¦+----------+------------------------------------------------------------¦¦¦
¦¦¦Descriçào ¦ Faz busca dos dados para apresentar no grid de resultaodos ¦¦¦
¦¦¦          ¦ 						                                      ¦¦¦
¦¦+----------+------------------------------------------------------------¦¦¦
¦¦¦Uso       ¦ Posto Inteligente			                              ¦¦¦
¦¦+-----------------------------------------------------------------------+¦¦
¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦
¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯
*/
Static Function DoFiltro(lRefresh)
	MsAguarde( {|| BuscaDados(lRefresh)}, "Aguarde", "Selecionando Preços Negociados...", .F. )
Return

Static Function BuscaDados(lRefresh)

	Local cQry := ""
	Local aNewLine := {}
	Local nX := 0
	Local cSeq := "00000"
	Local lAddNewLin := .T.
	Local nPrcCusto1 := 0
	Local nPrcCusto2 := 0
	Local cGrpCliVld := space(6)
	Local nPrcBase := 0
	Local lNgDesc := SuperGetMV("MV_XNGDESC",,.T.) //Ativa negociação pelo valor de desconto: U25_DESPBA

	Local aParcCond, dXDtIni, dXDtFim, nXSoma, nMediaFat, nPrazoMedio, aCondX

	Default lRefresh := .T.

	//limpando arrays
	ASize ( aDados1, 0)

	//fazer select e add registros retornados no acols1
	If Select("QRYTMP") > 0
		QRYTMP->(DbCloseArea())
	Endif

	cQry := " SELECT U25.R_E_C_N_O_ "
	cQry += " FROM "+RetSqlName("U25")+" U25 "

	cQry += " INNER JOIN "+RetSqlName("SB1")+" SB1 "
	cQry += " 	ON(SB1.D_E_L_E_T_ <> '*' AND B1_FILIAL = '"+xFilial("SB1")+"' AND B1_COD = U25_PRODUT ) "

	cQry += " LEFT JOIN "+RetSqlName("SA1")+" SA1 "
	cQry += " 	ON(SA1.D_E_L_E_T_ <> '*' AND A1_FILIAL = '"+xFilial("SA1")+"' AND A1_COD = U25_CLIENT AND A1_LOJA = U25_LOJA ) "

	cQry += " WHERE U25.D_E_L_E_T_ <> '*' "
	cQry += " 	AND U25_FILIAL = '"+xFilial("U25")+"' "
	cQry += " 	AND (U25_DTFIM = '' OR U25_DTFIM >= '"+DTOS(ddatabase)+"') " //somente com data de fim dentro da vigencia
	cQry += " 	AND U25_FLAGVD <> 'S' " //retira preços negociados para uma venda pontual
	cQry += " 	AND U25_BLQL <> 'S' " //nao bloqueado
	cQry += "	AND U25_PRODUT BETWEEN '"+ cProdDe +"' AND '"+ cProdAte +"' " //cod produto
	if !empty(cGrupPro)
		cQry += "	AND RTRIM(B1_GRUPO) IN ("+U_URetIn(cGrupPro,";")+") " //grupo produto
	endif
	if !empty(cFormaPg)
		cQry += "	AND RTRIM(U25_FORPAG) IN ("+U_URetIn(cFormaPg,";")+") " //forma pagto
	endif
	if !empty(cCondPg)
		cQry += "	AND RTRIM(U25_CONDPG) IN ("+U_URetIn(cCondPg,";")+") " //condição pagto
	endif
	if !empty(cAdmF)
		cQry += "	AND RTRIM(U25_ADMFIN) IN ("+U_URetIn(cAdmF,";")+") " //adm financeira
	endif
	cQry += "	AND U25_CLIENT BETWEEN '"+ cEmitenDe +"' AND '"+ cEmitenAte +"' " //cod emitente
	cQry += "	AND U25_LOJA BETWEEN '"+ cLojEmiDe +"' AND '"+ cLojEmiAte +"' " //loja emitente
	if lExcecao
		if !empty(cCliDe)
			cQry += "	AND ((U25_CLIENT+U25_LOJA) < '"+ cCliDe + cLojaDe +"' OR (U25_CLIENT+U25_LOJA) > '"+ cCliAte + cLojaAte +"') " //cod cliente
		endif
		if !empty(cGrupCli)
			cQry += "	AND ( (NVL(A1_GRPVEN,'"+ Space(TamSx3("ACY_GRPVEN")[1]) +"') NOT IN ("+U_URetIn(cGrupCli,";")+")) AND (U25_GRPCLI NOT IN ("+U_URetIn(cGrupCli,";")+")) ) " //grupo de clientes
		endif
		if !empty(cClasCli)
			cQry += "	AND NVL(A1_XCLASSE,'"+ Space(TamSx3("A1_XCLASSE")[1]) +"') NOT IN ("+U_URetIn(cClasCli,";")+") " //classe de clientes
		endif
		if !empty(cSegCli)
			cQry += "	AND NVL(A1_SATIV1,'"+ Space(TamSx3("A1_SATIV1")[1]) +"') NOT IN ("+U_URetIn(cSegCli,";")+") " //classe de clientes
		endif
		if !empty(cRiscoCli)
			cQry += "	AND RTRIM(A1_XRISCO) NOT IN ("+U_URetIn(cRiscoCli,";")+") " //adm financeira
		endif
	else
		cQry += "	AND (U25_CLIENT+U25_LOJA) BETWEEN '"+ cCliDe + cLojaDe +"' AND '"+ cCliAte + cLojaAte +"' " //cod cliente
		if !empty(cGrupCli)
			cQry += "	AND ( (NVL(A1_GRPVEN,'"+ Space(TamSx3("ACY_GRPVEN")[1]) +"') IN ("+U_URetIn(cGrupCli,";")+")) OR (U25_GRPCLI IN ("+U_URetIn(cGrupCli,";")+")) ) " //grupo de clientes
		endif
		if !empty(cClasCli)
			cQry += "	AND NVL(A1_XCLASSE,'"+ Space(TamSx3("A1_XCLASSE")[1]) +"') IN ("+U_URetIn(cClasCli,";")+") " //classe de clientes
		endif
		if !empty(cSegCli)
			cQry += "	AND NVL(A1_SATIV1,'"+ Space(TamSx3("A1_SATIV1")[1]) +"') IN ("+U_URetIn(cSegCli,";")+") " //classe de clientes
		endif
		if !empty(cRiscoCli)
			cQry += "	AND RTRIM(A1_XRISCO) IN ("+U_URetIn(cRiscoCli,";")+") " //adm financeira
		endif
	endif

	//condição para trazer somente ultimos preços de cada chave
	cQry += " AND (U25.U25_DTINIC+U25.U25_HRINIC) = ( "
	cQry += " 		SELECT Max((U25B.U25_DTINIC+U25B.U25_HRINIC)) "
	cQry += " 		FROM "+RetSqlName("U25")+" U25B "
	cQry += " 		WHERE U25B.D_E_L_E_T_ <> '*' "
	cQry += " 			AND U25B.U25_FILIAL = U25.U25_FILIAL "
	cQry += " 			AND U25B.U25_PRODUT = U25.U25_PRODUT "
	cQry += " 			AND U25B.U25_CLIENT = U25.U25_CLIENT "
	cQry += " 			AND U25B.U25_LOJA   = U25.U25_LOJA "
	cQry += " 			AND U25B.U25_GRPCLI = U25.U25_GRPCLI "
	cQry += " 			AND U25B.U25_FORPAG = U25.U25_FORPAG "
	cQry += " 			AND U25B.U25_CONDPG = U25.U25_CONDPG "
	cQry += " 			AND U25B.U25_ADMFIN = U25.U25_ADMFIN "
	cQry += " 			AND U25B.U25_EMITEN = U25.U25_EMITEN "
	cQry += " 			AND U25B.U25_LOJEMI = U25.U25_LOJEMI "
	cQry += " 			AND U25B.U25_BLQL <> 'S' "
	cQry += " 	) "

	if nDiasAtr > 0 .AND. !lExcecao //Atraso Cliente
		cQry += "	AND (U25_CLIENT+U25_LOJA) IN ( "
		cQry += "		SELECT DISTINCT (E1_CLIENTE+E1_LOJA) "
		cQry += "		FROM "+RetSqlName("SE1")+" SE1 "
		cQry += "		WHERE E1_FILIAL = '"+xFilial("SE1")+"' "
		cQry += "		  AND SE1.D_E_L_E_T_ <> '*' "
		cQry += "		  AND E1_SALDO > 0 "
		cQry += "		  AND E1_VENCREA < '"+DTOS(DDATABASE)+"' "
		cQry += "		  AND CONVERT(DATETIME, E1_VENCREA, 112) <= CONVERT(DATETIME, '"+DTOS(DDATABASE)+"', 112) - "+ alltrim(STR(nDiasAtr)) +" "
		cQry += "		) "
	endif

	cQry += " ORDER BY U25_DTINIC DESC, U25_HRINIC DESC, U25_PRODUT, U25_CLIENT, U25_LOJA, U25_FORPAG, U25_CONDPG, U25_ADMFIN, U25_EMITEN, U25_LOJEMI "

	cQry := ChangeQuery(cQry)
	TcQuery cQry NEW Alias "QRYTMP"

	DbSelectArea("U25")
	U25->(DbSetOrder(2))

	while QRYTMP->(!Eof())

		U25->(DbGoTo(QRYTMP->R_E_C_N_O_))

		nPrcBase := U_URetPrBa(U25->U25_PRODUT, U25->U25_FORPAG, U25->U25_CONDPG, U25->U25_ADMFIN, 0, U25->U25_DTINIC, U25->U25_HRINIC)

		if nPrecoDe > 0 .and. ; //preço de venda maior que
			iif( lNgDesc, ;
				(nPrcBase-U25->U25_DESPBA) < nPrecoDe, ;
				U25->U25_PRCVEN < nPrecoDe )
			QRYTMP->(dbSkip())
			loop //proximo while
		endif

		if nPrecoAte > 0 .and. ; //preço de venda menor que
			iif( lNgDesc, ;
				(nPrcBase-U25->U25_DESPBA) > nPrecoAte, ;
				U25->U25_PRCVEN > nPrecoAte )
			QRYTMP->(dbSkip())
			loop //proximo while
		endif

		if lNgDesc .and. ; //desconto/acrescimo do preço base maior que
			U25->U25_DESPBA < nDesPbDe
			QRYTMP->(dbSkip())
			loop //proximo while
		endif

		if lNgDesc .and. ; //desconto do preço base menor que
			U25->U25_DESPBA > nDesPbAte
			QRYTMP->(dbSkip())
			loop //proximo while
		endif

		if cPadrao <> "T"
			if Posicione("U44",1,xFilial("U44")+U25->U25_FORPAG+U25->U25_CONDPG, "U44_PADRAO") <> cPadrao
				QRYTMP->(dbSkip())
				loop //proximo while
			endif
		endif

		MsProcTxt("Selecionando Preços Negociados...: "+cSeq)
		nPrcVen := iif( lNgDesc, (nPrcBase-U25->U25_DESPBA), U25->U25_PRCVEN )

		//buscando preço de custo do produto
		/*
		nPrcCusto1 := 0
		nPrcCusto2 := 0
		if aScan(aCustoPrd, {|x| x[1] == U25->U25_PRODUT }) == 0
			DbSelectArea("SB2")
			SB2->(DbSetOrder(1))
			if SB2->(DbSeek(xFilial("SB2")+U25->U25_PRODUT))
				While SB2->(!Eof()) .AND. SB2->B2_FILIAL+SB2->B2_COD == xFilial("SB2")+U25->U25_PRODUT
					if SB2->B2_QATU > 0 .AND. SB2->B2_VATU1 > 0
						nPrcCusto1 += SB2->B2_QATU
						nPrcCusto2 += SB2->B2_VATU1
					endif
					SB2->(DbSkip())
				enddo

				nPrcCusto1 := nPrcCusto2 / nPrcCusto1
				nPrcCusto2 := nPrcCusto1

				aAdd(aCustoPrd, {U25->U25_PRODUT, nPrcCusto1})

			endif
		else
			nPrcCusto1 := aCustoPrd[aScan(aCustoPrd, {|x| x[1] == U25->U25_PRODUT })][2]
			nPrcCusto2 := nPrcCusto1
		endif
		*/

		Posicione("SB1",1,xFilial("SB1")+U25->U25_PRODUT,"B1_COD")
		nPrcCusto1 := Posicione("SB2",1,xFilial("SB2")+U25->U25_PRODUT+SB1->B1_LOCPAD,"B2_CM1") //preço de custo do produto
		nPrcCusto2 := nPrcCusto1

		if !empty(U25->U25_CLIENTE+U25->U25_LOJA)
			cGrpCliVld := Posicione("SA1",1,xFilial("SA1")+U25->U25_CLIENTE+U25->U25_LOJA,"A1_GRPVEN")
		endif

		DbSelectArea("U44")
		U44->(DbSetOrder(1))
		if U44->(DbSeek(xFilial("U44")+U25->U25_FORPAG+U25->U25_CONDPG))
			//Aplicando taxa de perda no custo do produto
			nPrcCusto2 := nPrcCusto2 * (1 + (U44->U44_TXPERD / 100))

			//Aplicando taxa de retorno no custo do produto
			nRetFat := Posicione("SE4",1,xFilial("SE4")+U44->U44_CONDPG,"E4_XRETFAT")
			if nRetFat > 0 //caso tenha RetFat

				//laço para descobrir diferença de faturamento da condição.
				aParcCond := condicao(100,U44->U44_CONDPG,0.00,dDatabase,0.00,{},,0)
				dXDtIni := aParcCond[1][1]
				dXDtFim := dXDtIni
				nXSoma := 1
				while dXDtIni == dXDtFim
					aCondX := condicao(100,U44->U44_CONDPG,0.00,dDatabase+nXSoma,0.00,{},,0)
					dXDtFim := aCondX[1][1]
					nXSoma++
				enddo

				nMediaFat := (DateDiffDay(dXDtFim, dXDtIni) / 2) //media faturamento

				nPrazoMedio := 0
				for nX := 1 to len(aParcCond)
					nPrazoMedio += DateDiffDay((dXDtIni-nRetFat),aParcCond[nX][1])
				next nX

				nPrazoMedio := nMediaFat + (nPrazoMedio / len(aParcCond))

			else  //senao, media padrão pelas datas
				nPrazoMedio := 0
				aParcCond := condicao(100,U44->U44_CONDPG,0.00,dDatabase,0.00,{},,0)

				for nX := 1 to len(aParcCond)
					nPrazoMedio += DateDiffDay(dDatabase,aParcCond[nX][1])
				next nX

				nPrazoMedio := nPrazoMedio / len(aParcCond)
			endif

			nPrcCusto2 += ( nPrcCusto2 * (U44->U44_TXRETO/100) * (nPrazoMedio/30) )
		endif

		//Rentabilidade
		if lAddNewLin .AND. (nRentDe > 0 .OR. nRentAte > 0)

			nPRentab := ((nPrcVen/nPrcCusto2)-1)*100

			//rentabilidade maior que
			if nRentDe > 0
				if nPRentab <= nRentDe //se rentabilidade for menor que parametro
					lAddNewLin := .F. //nao adiciona item
				endif
			endif

			//rentabilidade menor que
			if nRentAte > 0
				if nPRentab >= nRentAte //se rentabilidade for maior que parametro
					lAddNewLin := .F. //nao adiciona item
				endif
			endif

		endif

		if lAddNewLin
			aNewLine := {}
			for nX := 1 to Len(aHeader1)
				if aHeader1[nX][2] == 'MARK'
					Aadd(aNewLine, "LBNO")
				elseif aHeader1[nX][2] == 'SEQ'
					cSeq := soma1(cSeq)
					Aadd(aNewLine, cSeq)
				elseif aHeader1[nX][2] == "PLUCRO"
					if nPrcVen/nPrcCusto1 > 0
						aAdd(aNewLine, ((nPrcVen/nPrcCusto1)-1)*100 )
					else
						aAdd(aNewLine, 0 )
					endif
				elseif aHeader1[nX][2] == 'PRENTAB'
					if nPrcVen/nPrcCusto2 > 0
						aAdd(aNewLine, ((nPrcVen/nPrcCusto2)-1)*100 )
					else
						aAdd(aNewLine, 0 )
					endif
				elseif aHeader1[nX][2] == 'U25_PRCVEN'
					aAdd(aNewLine, nPrcVen)
				else
					If !Empty(GetSx3Cache(aHeader1[nX][2],"X3_CAMPO"))
						if aHeader1[nX][10] == "V" //se virtual
							Aadd(aNewLine, CriaVar(aHeader1[nX][2]))
						else
							Aadd(aNewLine, U25->&(aHeader1[nX][2]))
						endif
					Endif
				Endif
			Next nX

			aAdd(aNewLine, QRYTMP->R_E_C_N_O_) //recno
			aAdd(aNewLine, .F.) //deleted
			aAdd(aDados1, aNewLine)
		else
			lAddNewLin := .T.
		endif

		QRYTMP->(dbSkip())
	enddo

	if len(aDados1) == 0 //se nao teve resultados
		for nX := 1 to Len(aHeader1)
			if aHeader1[nX][2] == 'MARK'
				Aadd(aNewLine, "LBNO")
			elseif aHeader1[nX][2] == 'SEQ'
				Aadd(aNewLine, cSeq)
			elseif aHeader1[nX][2] == "PLUCRO"
				aAdd(aNewLine, 0)
			elseif aHeader1[nX][2] == 'PRENTAB'
				aAdd(aNewLine, 0)
			else
				If !Empty(GetSx3Cache(aHeader1[nX][2],"X3_CAMPO"))
					//Aadd(aNewLine, CriaVar(aHeader1[nX][2]))
					If aHeader1[nX][8] == "C"
						//If ExistIni(aHeader1[nX][2])
						//	Aadd(aNewLine, InitPad(aHeader1[nX][12]))
						//Else
						Aadd(aNewLine, SPACE(aHeader1[nX][4]))
						//EndIF
					ElseIf aHeader1[nX][8] == "N"
						Aadd(aNewLine, 0)
					ElseIf aHeader1[nX][8] == "D"
						Aadd(aNewLine, CTOD("  /  /  "))
					ElseIf aHeader1[nX][8] == "M"
						Aadd(aNewLine, "")
					Else //boleano
						Aadd(aNewLine, .F.)
					EndIf
				Endif
			Endif
		Next nX

		aAdd(aNewLine, 0) //recno
		aAdd(aNewLine, .F.) //deleted
		aAdd(aDados1, aNewLine)
	endif

	QRYTMP->(DbCloseArea())

	if lRefresh
		oMSNewGe1:oBrowse:Refresh()
	endif

Return

/*
_____________________________________________________________________________
¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦
¦¦+-----------------------------------------------------------------------+¦¦
¦¦¦Programa  ¦ Marcar      ¦ Autor ¦ Totvs GO         ¦ Data ¦ 29/01/2014 ¦¦¦
¦¦+----------+------------------------------------------------------------¦¦¦
¦¦¦Descriçào ¦ Marcação da linha do Acols								  ¦¦¦
¦¦¦          ¦                                                            ¦¦¦
¦¦+----------+------------------------------------------------------------¦¦¦
¦¦¦Uso       ¦ TOTVS - GO		                                          ¦¦¦
¦¦+-----------------------------------------------------------------------+¦¦
¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦
¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯
*/
Static Function Marcar()

	if oMSNewGe1:ACols[oMSNewGe1:nAt][1] == "LBOK"
		oMSNewGe1:ACols[oMSNewGe1:nAt][1] := "LBNO"
	else
		oMSNewGe1:ACols[oMSNewGe1:nAt][1] := "LBOK"
	endif

	oMSNewGe1:oBrowse:Refresh()

return

/*
_____________________________________________________________________________
¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦
¦¦+-----------------------------------------------------------------------+¦¦
¦¦¦Programa  ¦ MarcaTodos  ¦ Autor ¦ Totvs GO         ¦ Data ¦ 29/01/2014 ¦¦¦
¦¦+----------+------------------------------------------------------------¦¦¦
¦¦¦Descriçào ¦ Marca/Desmarca todos Acols								  ¦¦¦
¦¦¦          ¦                                                            ¦¦¦
¦¦+----------+------------------------------------------------------------¦¦¦
¦¦¦Uso       ¦ TOTVS - GO		                                          ¦¦¦
¦¦+-----------------------------------------------------------------------+¦¦
¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦
¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯
*/
Static Function MarcaTodos()
	Local NX

	IF __XVEZ == "0"
		__XVEZ := "1"
	ELSE
		IF __XVEZ == "1"
			__XVEZ := "2"
		ENDIF
	ENDIF

	If __XVEZ == "2"
		If nMarca == 0
			FOR NX := 1 TO LEN(oMSNewGe1:ACOLS)
				oMSNewGe1:ACOLS[NX][1] := "LBOK"
			Next
			nMarca := 1
		Else
			FOR NX := 1 TO LEN(oMSNewGe1:ACOLS)
				oMSNewGe1:ACOLS[NX][1] := "LBNO"
			Next
			nMarca := 0
		Endif
		__XVEZ:="0"

		oMSNewGe1:oBrowse:REFRESH()
	Endif

Return

/*
_____________________________________________________________________________
¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦
¦¦+-----------------------------------------------------------------------+¦¦
¦¦¦Programa  ¦ fMSNewGe2    ¦ Autor ¦ Totvs          ¦ Data ¦ 15/01/2014 ¦¦¦
¦¦+----------+------------------------------------------------------------¦¦¦
¦¦¦Descriçào ¦ Cria grid da tela pedidos								  ¦¦¦
¦¦¦          ¦                                                            ¦¦¦
¦¦+----------+------------------------------------------------------------¦¦¦
¦¦¦Uso       ¦ TOTVS - GO		                                          ¦¦¦
¦¦+-----------------------------------------------------------------------+¦¦
¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦
¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯
*/
Static Function fMSNewGe2(oComp)

	Local nX, aSX3U25
	Local aAlterFields := {}
	Local aTemp := {}
	Local aNewLine := {}

	Aadd(aHeader2,{}) //[1] Cod Prod.
	Aadd(aHeader2,{}) //[2] Desc. Prod.
	Aadd(aHeader2,{}) //[3] Preço Base
	Aadd(aHeader2,{}) //[4] Valor Anterior (virtual)
	Aadd(aHeader2,{}) //[5] Valor Novo Valor (U25_PRCVEN)
	Aadd(aHeader2,{}) //[6] Data Inic
	Aadd(aHeader2,{}) //[7] Hora Inic
	Aadd(aHeader2,{}) //[8] Desc/Acres Anterior (virtual)
	Aadd(aHeader2,{}) //[9] Desc/Acres Novo Valor (U25_DESPBA)

	// Define field properties
	aSX3U25 := FWSX3Util():GetAllFields( "U25" , .T./*lVirtual*/ )
	If !empty(aSX3U25)
		For nX := 1 to len(aSX3U25)
			If (X3Uso(GetSx3Cache(aSX3U25[nX],"X3_USADO")) .OR. GetSx3Cache(aSX3U25[nX],"X3_BROWSE") == 'S') .and. cNivel>=GetSx3Cache(aSX3U25[nX],"X3_NIVEL")
				aTemp := U_UAHEADER(aSX3U25[nX])

				if GetSx3Cache(aSX3U25[nX],"X3_VISUAL") == "A"
					aadd(aAlterFields, aSX3U25[nX])
				endif

				if alltrim(aSX3U25[nX]) == "U25_PRODUT"
					aHeader2[1] := aTemp
				elseif alltrim(aSX3U25[nX]) == "U25_DESPRO"
					aHeader2[2] := aTemp
				elseif alltrim(aSX3U25[nX]) == "U25_PRCBAS"
					aHeader2[3] := aTemp
				elseif alltrim(aSX3U25[nX]) == "U25_PRCVEN"
					aHeader2[4] := aClone(aTemp)
					aHeader2[4][1] := "Preço Anterior"
					aHeader2[4][2] := "PRCANTE"
					aHeader2[5] := aClone(aTemp)
					aHeader2[5][1] := "Novo Preço"
				elseif alltrim(aSX3U25[nX]) == "U25_DTINIC"
					aHeader2[6] := aTemp
				elseif alltrim(aSX3U25[nX]) == "U25_HRINIC"
					aHeader2[7] := aTemp
				elseif alltrim(aSX3U25[nX]) == "U25_DESPBA"
					aHeader2[8] := aClone(aTemp)
					aHeader2[8][1] := "Desc/Acres Anterior"
					aHeader2[8][2] := "DESANTE"
					aHeader2[9] := aClone(aTemp)
					aHeader2[9][1] := "Novo Desc/Acres"
				else
					Aadd(aHeader2, aTemp)
				endif

			endif
		Next nX
	EndIf

	//validando posições fixas
	for nX := 1 to 9
		if len(aHeader2[nX]) == 0
			Alert("Campos obrigatorios da rotina não estão configurados corretamente na base SX3.")
			return Nil
		endif
	next nX

	//inserindo linha em branco no aCols
	for nX := 1 to Len(aHeader2)
		if aHeader2[nX][2] == 'PRCANTE'
			Aadd(aNewLine, 0)
		elseif aHeader2[nX][2] == 'DESANTE'
			Aadd(aNewLine, 0)
		else
			If !Empty(GetSx3Cache(aHeader2[nX][2],"X3_CAMPO"))
				//Aadd(aNewLine, CriaVar(aHeader2[nX][8]))
				If aHeader2[nX][8] == "C"
					//If ExistIni(aHeader2[nX][8])
					//	Aadd(aNewLine, InitPad(aHeader2[nX][12]))
					//Else
					Aadd(aNewLine, SPACE(aHeader2[nX][4]))
					//EndIF
				ElseIf aHeader2[nX][8] == "N"
					Aadd(aNewLine, 0)
				ElseIf aHeader2[nX][8] == "D"
					Aadd(aNewLine, CTOD("  /  /  "))
				ElseIf aHeader2[nX][8] == "M"
					Aadd(aNewLine, "")
				Else //boleano
					Aadd(aNewLine, .F.)
				EndIf
			Endif
		Endif
	Next nX

	aAdd(aNewLine, .F.) //deleted
	aAdd(aDados2, aNewLine)

Return MsNewGetDados():New( aPObj[2,1]+40,aPObj[2,2]+2,aPObj[2,3]-3,aPObj[2,4]-2, GD_INSERT+GD_UPDATE+GD_DELETE , ;
		"U_TRETA24A()", "AllwaysTrue",, aAlterFields,, 9999, "AllwaysTrue", "", "AllwaysTrue", oComp, aHeader2, aDados2)

/*
_____________________________________________________________________________
¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦
¦¦+-----------------------------------------------------------------------+¦¦
¦¦¦Programa  ¦ TRETA24A    ¦ Autor ¦ Totvs GO         ¦ Data ¦ 25/04/2014 ¦¦¦
¦¦+----------+------------------------------------------------------------¦¦¦
¦¦¦Descriçào ¦ Validação da linha do Acols do GetDados2					  ¦¦¦
¦¦¦          ¦ 						                                      ¦¦¦
¦¦+----------+------------------------------------------------------------¦¦¦
¦¦¦Uso       ¦ Posto Inteligente			                              ¦¦¦
¦¦+-----------------------------------------------------------------------+¦¦
¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦
¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯
*/
User Function TRETA24A()

	Local lRet := .T.
	Local aCampos := MSGet2Arr(oMSNewGe2, oMSNewGe2:nAt)

	lRet := VldAddItem(aCampos, ,oMSNewGe2:nAt)

Return lRet

/*
_____________________________________________________________________________
¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦
¦¦+-----------------------------------------------------------------------+¦¦
¦¦¦Programa  ¦ AddItens    ¦ Autor ¦ Totvs GO         ¦ Data ¦ 25/04/2014 ¦¦¦
¦¦+----------+------------------------------------------------------------¦¦¦
¦¦¦Descriçào ¦ Validação de insersão de item no Acols do GetDados2		  ¦¦¦
¦¦¦          ¦ 						                                      ¦¦¦
¦¦+----------+------------------------------------------------------------¦¦¦
¦¦¦Uso       ¦ Posto Inteligente			                              ¦¦¦
¦¦+-----------------------------------------------------------------------+¦¦
¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦
¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯
*/
Static Function AddItens()
	MsAguarde( {|| AddItAguar()}, "Aguarde", "Calculando novos Preços Negociados...", .F. )
Return

Static Function AddItAguar()

	Local nX := 0, nY := 0
	Local lMark := .F.
	Local lValid := .T.
	Local aNewLine := {}
	Local nNewPrcV := 0
	Local aCampos
	Local aItInclu := {}

	Local nPosTmp  := 0
	Local nPosPr2  := aScan(aHeader2,{|x| Trim(x[2])=="U25_PRODUT"})
	Local nPosProd := aScan(aHeader1,{|x| Trim(x[2])=="U25_PRODUT"})
	Local nPosPrcV := aScan(aHeader1,{|x| Trim(x[2])=="U25_PRCVEN"})
	Local nPosDesc := aScan(aHeader1,{|x| Trim(x[2])=="U25_DESPBA"})
	Local nPosDtIni,nPosHrIni,nPosNPrc,nPosNDes,nPosCPro,nPosCli,nPosLoja,nPosForma,nPosCond,nPosEmit,nPosAdmF,nPosLojEm,nPosGrpC
	Local cLogProc := ""
	Local lNgDesc := SuperGetMV("MV_XNGDESC",,.T.) //Ativa negociação pelo valor de desconto: U25_DESPBA

	aDados2 := oMSNewGe2:aCols //defino aDados2 mesmo que aCols

	//verificando se marcou pelo menos 1
	if len(aDados1) > 0
		for nX:=1 to len(aDados1)
			if aDados1[nX][1] == "LBOK" .AND. !empty(aDados1[nX][nPosProd])
				lMark := .T.
				EXIT
			endif
		next nX
	endif

	if !lMark
		Help('',1,'SELECAO',,"Selecione pelo menos um preço negociado para atualização.",1,0)
		lValid := .F.
		Return
	endif

	if lValid .AND. empty(dtos(_dDtInic))
		Help('',1,'GETOBG',,'Defina uma data de início para que sejam inseridos os novos preços.',1,0)
		lValid := .F.
		Return
	endif

	if lValid .AND. empty(_cTpCalc)
		Help('',1,'GETOBG',,'Escolha um tipo de cálculo a ser aplicado aos novos preços.',1,0)
		lValid := .F.
		Return
	endif

	if lValid .AND. !(_cTpCalc $ "1/ ") .AND. empty(_cTipoAD)
		Help('',1,'GETOBG',,'Escolha um tipo de valor a ser aplicado aos novos preços.',1,0)
		lValid := .F.
		Return
	endif

	//validando se os itens marcados poderão ser inseridos no grid
	if lValid
		for nX:=1 to len(aDados1)
			if aDados1[nX][1] == "LBOK" .AND. !empty(aDados1[nX][nPosProd])
				aCampos := MSGet2Arr(oMSNewGe1, nX, .T.)

				MsProcTxt("Calculando novos preços... Item: "+aDados1[nX][2])

				nPosDtIni := aScan(aCampos,{|x| Trim(x[1])=="U25_DTINIC"})
				nPosHrIni := aScan(aCampos,{|x| Trim(x[1])=="U25_HRINIC"})
				nPosNPrc  := aScan(aCampos,{|x| Trim(x[1])=="U25_PRCVEN"})
				nPosNDes  := aScan(aCampos,{|x| Trim(x[1])=="U25_DESPBA"})
				nPosCPro  := aScan(aCampos,{|x| Trim(x[1])=="U25_PRODUT"})
				nPosCli   := aScan(aCampos,{|x| Trim(x[1])=="U25_CLIENT"})
				nPosLoja  := aScan(aCampos,{|x| Trim(x[1])=="U25_LOJA"})
				nPosGrpC  := aScan(aCampos,{|x| Trim(x[1])=="U25_GRPCLI"})
				nPosForma := aScan(aCampos,{|x| Trim(x[1])=="U25_FORPAG"})
				nPosCond  := aScan(aCampos,{|x| Trim(x[1])=="U25_CONDPG"})
				nPosAdmF  := aScan(aCampos,{|x| Trim(x[1])=="U25_ADMFIN"})
				nPosEmit  := aScan(aCampos,{|x| Trim(x[1])=="U25_EMITEN"})
				nPosLojEm := aScan(aCampos,{|x| Trim(x[1])=="U25_LOJEMI"})

				nPrcBase := U_URetPrBa(aCampos[nPosCPro][2],aCampos[nPosForma][2],aCampos[nPosCond][2],aCampos[nPosAdmF][2],0,aCampos[nPosDtIni][2],aCampos[nPosHrIni][2])

				If lNgDesc
					aCampos[nPosNPrc][2] := iif( lNgDesc, (nPrcBase-aCampos[nPosNDes][2]), aCampos[nPosNPrc][2] )
				EndIf

				//CalcNewPrc(_cCodProd,_cCliente,_cLoja,_cGrpCli,cForma,cCondPg,cAdmFina,cEmiCh,cLojEmi,dDtInic,cHrInic,nOldPrc,cSeq)
				nNewPrcV := CalcNewPrc(aCampos[nPosCPro][2],aCampos[nPosCli][2],aCampos[nPosLoja][2],aCampos[nPosGrpC][2],aCampos[nPosForma][2],aCampos[nPosCond][2],;
					aCampos[nPosAdmF][2],aCampos[nPosEmit][2],aCampos[nPosLojEm][2],aCampos[nPosDtIni][2],aCampos[nPosHrIni][2],;
					aCampos[nPosNPrc][2],aDados1[nX][2])

				aCampos[nPosDtIni][2] := _dDtInic
				aCampos[nPosHrIni][2] := _cHrInic
				aCampos[nPosNPrc][2]  := nNewPrcV
				aCampos[nPosNDes][2]  := nPrcBase-nNewPrcV

				cLogU25 := ""
				if VldAddItem(aCampos ,aDados1[nX][2]/*seq*/,0, @cLogU25)
					aadd(aItInclu, {aClone(aCampos), nX} )
				else
					//lValid := .F.
					cLogProc += cLogU25 + chr(13)+chr(10)
					cLogProc += chr(13)+chr(10) + "##############################################" + chr(13)+chr(10)
					//exit
				endif
			endif
		next nX
	endif

	lValid := (Len(aItInclu) > 0)
	If !lValid
		if !empty(cLogProc)
			ShowLog(cLogProc)
		endif
		Return
	EndIf

	//Ponto de Entrada validação de inclusão dos itens selecionados
	//If lValid .AND. ExistBlock("UF02VADD")
	//	lValid := ExecBlock("UF02VADD",.F.,.F.)
	//	if Type("lValid") != "L"
	//		lValid := .T.
	//	endif
	//EndIf

	//se tudo válido, insere itens marcados
	if lValid
		if len(aDados2) == 1 .AND. empty(aDados2[1][nPosPr2])
			aSize(aDados2,0)  //limpa acols se não tem registro inserido ainda
		endif

		for nX:=1 to len(aItInclu)

			aNewLine := {}

			//inserindo valores nos campos da linha
			for nY := 1 to Len(aHeader2)
				if Trim(aHeader2[nY][2]) == 'PRCANTE'
					Aadd(aNewLine, aDados1[aItInclu[nX][2]][nPosPrcV])
				elseif Trim(aHeader2[nY][2]) == 'DESANTE'
					Aadd(aNewLine, aDados1[aItInclu[nX][2]][nPosDesc])
				elseif Trim(aHeader2[nY][2]) == 'U25_TIPOAJ'
					Aadd(aNewLine, "R")
				else
					if aHeader2[nY][10] == "V" //se virtual
						nPosTmp := aScan(aHeader1,{|x| Trim(x[2])==Trim(aHeader2[nY][2]) }) //pegando posição do campo no acols de cima
						Aadd(aNewLine, aDados1[aItInclu[nX][2]][nPosTmp])
					else
						nPosTmp := aScan(aItInclu[nX][1],{|x| Trim(x[1])==Trim(aHeader2[nY][2]) }) //pegando posição do campo no acols de cima
						if nPosTmp > 0
							Aadd(aNewLine, aItInclu[nX][1][nPosTmp][2])
						else
							Aadd(aNewLine, "")
						endif
					endif
				endif
			next nY

			aAdd(aNewLine, .F.) //deleted
			aAdd(aDados2, aNewLine)

		next nX

	endif

	if !empty(cLogProc)
		ShowLog(cLogProc)
	endif

Return

//abre janela do tipo help, mostrando o problema e solução
Static Function ShowLog(_cGetMsg)

	Local oGetMsg
	Local cGetMsg := ""
	Local oSButton1
	Local cGetMsg := ""
	Default _cGetMsg := "TESTE"
	Private oHelp

	cGetMsg := _cGetMsg

	DEFINE MSDIALOG oHelp TITLE "LOG PROCESSAMENTO" FROM 000, 000  TO 500, 700 COLORS 0, 16777215 PIXEL

	@ 02, 02 GET oGetMsg VAR cGetMsg OF oHelp MULTILINE SIZE 346, 225 COLORS 0, 16777215 READONLY PIXEL

	DEFINE SBUTTON oSButton1 FROM 230, 180 TYPE 01 OF oHelp ACTION (oHelp:end()) ENABLE

	ACTIVATE MSDIALOG oHelp CENTERED ON INIT (oSButton1:SetFocus())

Return

/*
_____________________________________________________________________________
¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦
¦¦+-----------------------------------------------------------------------+¦¦
¦¦¦Programa  ¦ VldAddItem  ¦ Autor ¦ Totvs GO         ¦ Data ¦ 25/04/2014 ¦¦¦
¦¦+----------+------------------------------------------------------------¦¦¦
¦¦¦Descriçào ¦ Validação de insersão de item no Acols do GetDados2		  ¦¦¦
¦¦¦          ¦ 						                                      ¦¦¦
¦¦+----------+------------------------------------------------------------¦¦¦
¦¦¦Uso       ¦ Posto Inteligente			                              ¦¦¦
¦¦+-----------------------------------------------------------------------+¦¦
¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦
¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯
*/
Static Function VldAddItem(aCampos, cSeq, _nAt, cLogU25)

	Local lRet 			:= .T.
	Local aChvs 		:= {"",""}
	Local cMsgSeq 		:= iif(cSeq==Nil,"","Item Seq.: "+cSeq+cEOL)
	Local aCpsChav 		:= {}
	Local nX			:= 0
	Local nPosCampos	:= 0

	lRet := U_TRET023B(aCampos, cSeq, @cLogU25) //chama validação da rotina RFATA001

	//valida se já inseriu no aDados2 com mesmas configurações
	if lRet

		aDados2 := oMSNewGe2:aCols //defino aDados2 mesmo que aCols

		aCpsChav := U_TRET023A(,.T.) //pego os campos chaves

		//TODO: verificar campos de filial
		aChvs[1] := "xFilial('U25')" //"U25->U25_FILIAL"
		aChvs[2] := xFilial("U25")

		for nX := 1 to len(aCpsChav)

			// verifico se o campo existe
			nPosCampos := aScan(aCampos,{|x| Trim(x[1])== Alltrim(aCpsChav[nX])})

			// caso tenha encontrado o campo adiciono no retorno
			If nPosCampos > 0
				aChvs[1] += "+RetChar(aDados2[nX]["+alltrim(str(nPosCampos))+"])"
				aChvs[2] += aCampos[nPosCampos][2]
			EndIf

		next nX

		for nX := 1 to len(aDados2)
			if nX != _nAt .AND. !aDados2[nX][len(aHeader2)+1] //se não é o mesmo e não deletado

				if &(aChvs[1]) == aChvs[2]
					cLogU25 := cMsgSeq
					cLogU25 += "-> Mensagem: Preço Negociado já inserido com as mesmas chaves.
					//Help('',1,'EXISTCHAV',,cMsgSeq+"Preço Negociado já inserido com as mesmas chaves.",1,0)
					lRet := .F.
					EXIT
				endif
			endif

		next nX

	endif

Return lRet

/*/{Protheus.doc} RetChar
Funcao para converter os dados em character
@type function
@version 1.0
@author g.sampaio
@since 05/09/2023
@param xRetorno, variant, informação a ver validada
@return character, retorno da informação em character
/*/
Static Function RetChar(xValue)

	Local aArea		:= GetArea()
	Local cRetorno	:= ""
	Local cType		:= ""
	Local nI		:= 0

	Default xValue	:= Nil

	// pego o tipo do prametro
	cType := valType(xValue)

	DO CASE
	case cType == "C"
		cRetorno :=  '"'+ xValue +'"'
	case cType == "N"
		cRetorno := cValToChar(xValue)
	case cType == "L"
		cRetorno := if(xValue,"true","false")
	case cType == "D"
		cRetorno := '"'+ DtoC(xValue) +'"'
	case cType == "U"
		cRetorno := "null"
	case cType == "A"
		cRetorno := '['

		For nI := 1 to len(xValue)
			if(nI != 1)
				cRetorno += ', '
			endif
			cRetorno += U_toString(xValue[nI])
		Next

		cRetorno += ']'
	case cType == "B"
		cRetorno := '"Type Block"'
	case cType == "M"
		cRetorno := '"Type Memo"'
	case cType =="O"
		cRetorno := '"Type Object"'
	case cType =="H"
		cRetorno := '"Type Object"'
	OtherWise
		cRetorno := "invalid type"
	ENDCASE

	RestArea( aArea )

Return(cRetorno)

//Função para montar array aDados, para utilizar em validação/inclusão
Static Function MSGet2Arr(oMsNewGet, nAt, lVirtual)
	Local aRet := {}
	Local nX := 0
	Default lVirtual := .F.

	for nX := 1 to Len(oMsNewGet:aHeader)
		if Alltrim(oMsNewGet:aHeader[nX][2]) $ 'MARK/SEQ/PLUCRO/PRENTAB/PRCANTE/DESANTE/'
		elseif oMsNewGet:aHeader[nX][10] == "R" .OR. lVirtual
			AAdd(aRet, {oMsNewGet:aHeader[nX][2], oMsNewGet:aCols[nAt][nX] })
		Endif
	Next nX

Return aRet

/*
_____________________________________________________________________________
¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦
¦¦+-----------------------------------------------------------------------+¦¦
¦¦¦Programa  ¦ CalcNewPrc  ¦ Autor ¦ Totvs GO         ¦ Data ¦ 17/04/2014 ¦¦¦
¦¦+----------+------------------------------------------------------------¦¦¦
¦¦¦Descriçào ¦ Calcula novo preço de venda de acordo com configurações	  ¦¦¦
¦¦¦          ¦ escolhidas.												  ¦¦¦
¦¦+----------+------------------------------------------------------------¦¦¦
¦¦¦Uso       ¦ Posto Inteligente			                              ¦¦¦
¦¦+-----------------------------------------------------------------------+¦¦
¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦
¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯
*/
Static Function CalcNewPrc(_cCodProd,_cCliente,_cLoja,_cGrpCli,cForma,cCondPg,cAdmFina,cEmiCh,cLojEmi,dDtInic,cHrInic,nOldPrc,cSeq)

	Local nRet := 0

	if _cTpCalc == "1" //preço fixo
		nRet := _nValAju
	elseif _cTpCalc == "2" //acrescimo
		if _cTipoAD == "1" //Percentual
			nRet := nOldPrc * (1+(_nValAju/100.0))
		else //Valor
			nRet := nOldPrc + _nValAju
		endif
	elseif _cTpCalc == "3" //desconto
		if _cTipoAD == "1" //Percentual
			nRet := nOldPrc * (1-(_nValAju/100.0))
		else //Valor
			nRet := nOldPrc - _nValAju
		endif
	endif

Return nRet

/*
_____________________________________________________________________________
¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦
¦¦+-----------------------------------------------------------------------+¦¦
¦¦¦Programa  ¦ DoGrava   ¦ Autor ¦ Totvs GO           ¦ Data ¦ 17/04/2014 ¦¦¦
¦¦+----------+------------------------------------------------------------¦¦¦
¦¦¦Descriçào ¦ Faz gravação das novas regras de negociação      		  ¦¦¦
¦¦¦          ¦ 															  ¦¦¦
¦¦+----------+------------------------------------------------------------¦¦¦
¦¦¦Uso       ¦ Posto Inteligente			                              ¦¦¦
¦¦+-----------------------------------------------------------------------+¦¦
¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦
¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯
*/
Static Function DoGrava()
	Local lRet := .F.
	MsAguarde( {|| lRet := DoGravaAg() }, "Aguarde", "Gravando novos Preços Negociados...", .F. )
Return lRet

Static Function DoGravaAg()

	Local nPosProd := aScan(aHeader1,{|x| Trim(x[2])=="U25_PRODUT"})
	Local nPosSeq  := aScan(aHeader1,{|x| Trim(x[2])=="SEQ"})
	Local nPosPr2
	Local nX := 0
	Local lValid := .T.
	Local aCamposTmp := {}
	Local nRecSM0 := SM0->(Recno())
	Local cBkpFil := cFilAnt
	Local lMark := .F.
	Local nPosDtIni := nPosHrIni := 0
	Local aItensRep := {}
	Local cMV_XFLTPDV := SuperGetMv("MV_XFLTPDV",,"") //filiais que ja são totvspdv
	Local nPosForPag := 0

	if lRepFil
		//verificando se marcou pelo menos 1
		if len(aDados1) > 0
			for nX:=1 to len(aDados1)
				if aDados1[nX][1] == "LBOK" .AND. !empty(aDados1[nX][nPosProd])
					lMark := .T.
					EXIT
				endif
			next nX
		endif
		if !lMark
			Help('',1,'SELECAO',,"Selecione pelo menos um preço negociado para atualização.",1,0)
			lValid := .F.
		endif

		if lValid .AND. empty(dtos(_dDtInic))
			Help('',1,'GETOBG',,'Defina uma data de início para que sejam inseridos os novos preços.',1,0)
			lValid := .F.
		endif

		if lValid .AND. empty(_cFilDest)
			Help('',1,'GETOBG',,'Escolha uma Filial para processamento.',1,0)
			lValid := .F.
		endif

		if lValid .AND. _cFilDest == cFilAnt
			Help('',1,'HELP',,'Não é permitido usar a mesma filial logada no processamento.',1,0)
			lValid := .F.
		endif

		if lValid
			lValid := .F.
			SM0->(DbGoTop())
			while SM0->(!Eof())
				if alltrim(SM0->M0_CODIGO) = cEmpAnt .AND. alltrim(SM0->M0_CODFIL) == _cFilDest
					lValid := .T.
					EXIT
				endif

				SM0->(DbSkip())
			enddo
			if !lValid
				Help('',1,'HELP',,'Filial informada não existe ou não está cadastrada.',1,0)
			endif
		endif

		//altero filial para processamento
		cFilAnt := _cFilDest
		DbSelectArea("U25")

		//faço validação de item a item... e ja prepara dados para inclusão
		if lValid
			if len(aDados1) > 0
				for nX:=1 to len(aDados1)
					if aDados1[nX][1] == "LBOK" .AND. !empty(aDados1[nX][nPosProd])
						aCamposTmp := MSGet2Arr(oMSNewGe1, nX)

						nPosDtIni := aScan(aCamposTmp,{|x| Trim(x[1])=="U25_DTINIC"})
						nPosHrIni := aScan(aCamposTmp,{|x| Trim(x[1])=="U25_HRINIC"})
						nPosForPag := aScan(aCamposTmp,{|x| Trim(x[1])=="U25_FORPAG"})

						aCamposTmp[nPosDtIni][2] := _dDtInic
						aCamposTmp[nPosHrIni][2] := _cHrInic

						//DANILO: alteração de CCP e CDP para CC e CD
						if cFilAnt $ cMV_XFLTPDV
							if Alltrim(aCamposTmp[nPosForPag][2]) == "CCP"
								aCamposTmp[nPosForPag][2] :=  "CC "
							elseif Alltrim(aCamposTmp[nPosForPag][2]) == "CDP"
								aCamposTmp[nPosForPag][2] :=  "CD "
							elseif Alltrim(aCamposTmp[nPosForPag][2]) == "CR"
								aCamposTmp[nPosForPag][2] :=  "NB "
							endif
						endif

						if U_TRET023B( aCamposTmp, aDados1[nX][nPosSeq] )
							aadd(aItensRep, aClone( aCamposTmp ) )
						else
							lValid := .F.
							EXIT
						endif
					endif
				next nX
			endif
		endif

		if lValid
			//Begin Transaction

			for nX:=1 to len(aItensRep)

				U_TRET023C("R", aItensRep[nX] )

			next nX

			//Ponto de Entrada após inclusão do itens de preço
			//If ExistBlock("UF002FIM")
			//	ExecBlock("UF002FIM",.F.,.F.)
			//EndIf

			//End Transaction
		endif

	else
		nPosPr2  := aScan(aHeader2,{|x| Trim(x[2])=="U25_PRODUT"})
		lValid := .F.

		if len(aDados2) > 0
			for nX:=1 to len(aDados2)
				if !empty(aDados2[nX][nPosPr2]) .AND. !aDados2[nX][len(aDados2[nX])] //não deletado
					lValid := .T.
					EXIT
				endif
			next nX
		endif
		if !lValid
			Help('',1,'GETOBG',,"Preencha pelo menos um novo preço negociado.",1,0)
		endif

		if lValid .AND. !oMSNewGe2:LinhaOk()
			lValid := .F.
		endif

		if lValid
			//Begin Transaction

			for nX:=1 to len(aDados2)
				if !aDados2[nX][len(aDados2[nX])] //não deletado

					DbSelectArea("U25")
					aCamposTmp := MSGet2Arr(oMSNewGe2, nX)

					U_TRET023C("R", aCamposTmp)

				endif
			next nX

			//Ponto de Entrada após inclusão do itens de preço
			//If ExistBlock("UF002FIM")
			//	ExecBlock("UF002FIM",.F.,.F.)
			//EndIf

			//End Transaction

			MsgInfo("Atualização de preços negociados realizada com sucesso!")
		endif
	endif

	SM0->(DbGoTo(nRecSM0))
	cFilAnt := cBkpFil

return lValid

/*
_____________________________________________________________________________
¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦
¦¦+-----------------------------------------------------------------------+¦¦
¦¦¦Programa  ¦ DoExcluiSel   ¦ Autor ¦ Totvs GO       ¦ Data ¦ 17/04/2014 ¦¦¦
¦¦+----------+------------------------------------------------------------¦¦¦
¦¦¦Descriçào ¦ Faz exclusão dos itens selecionados de  negociação.  	  ¦¦¦
¦¦¦          ¦ 															  ¦¦¦
¦¦+----------+------------------------------------------------------------¦¦¦
¦¦¦Uso       ¦ Posto Inteligente			                              ¦¦¦
¦¦+-----------------------------------------------------------------------+¦¦
¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦
¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯
*/
Static Function DoExcluiSel()

	Local nPosProd  := aScan(aHeader1,{|x| Trim(x[2])=="U25_PRODUT"})
	Local nX := 0, nY := 0
	Local lValid := .F.
	Local cChvRep := ""
	Local _cUser := RetCodUsr()

	//cadastra rotina para controle de acesso
	U_TRETA37B("U25DEL", "EXCLUSÃO DE PREÇO NEGOCIADO")

	//verifica se o usuário tem permissão para acesso a rotina
	cUsrCmp := U_VLACESS1("U25DEL", RetCodUsr())
	if cUsrCmp == Nil .OR. empty(cUsrCmp)
		Return
	endif

	if MsgYesNo("Deseja realmente excluir os itens de preço selecionados?","Atenção!")

		if len(aDados1) > 0

			DbSelectArea("U25")
			//Begin Transaction

			for nX:=1 to len(aDados1)
				if aDados1[nX][1] == "LBOK" .AND. !empty(aDados1[nX][nPosProd]) //se linha marcada
					U25->(DbGoto(aDados1[nX][len(aDados1[nX])-1]))

					cChvRep := U25->U25_FILIAL+U25->U25_REPLIC

					RecLock("U25", .F.)
					U25->U25_OBS := U25->U25_OBS + CHR(13)+CHR(10) + "Exclusão Manual <R> (Data/Hora: "+DTOC(Date())+" "+Time()+". Usuário: "+iif(IsBlind(),"JOB",_cUser)+")"
					U25->(DbDelete())
					U25->(MsUnlock())

					U_UREPLICA("U25", 1, cChvRep, "E")

					aDados1[nX][len(aDados1[nX])] := .T.  //seta como deletado
				endif
			next nX

			//End Transaction

		endif

	endif

return .T.

/*
_____________________________________________________________________________
¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦
¦¦+-----------------------------------------------------------------------+¦¦
¦¦¦Programa  ¦ DoParam     ¦ Autor ¦ Totvs GO         ¦ Data ¦ 25/04/2014 ¦¦¦
¦¦+----------+------------------------------------------------------------¦¦¦
¦¦¦Descriçào ¦ Chama tela de perguntas e validação dos parametros		  ¦¦¦
¦¦¦          ¦ 						                                      ¦¦¦
¦¦+----------+------------------------------------------------------------¦¦¦
¦¦¦Uso       ¦ Posto Inteligente			                              ¦¦¦
¦¦+-----------------------------------------------------------------------+¦¦
¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦
¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯
*/
Static Function DoParam()
	Local lBotaoOk := .F.
	Local oAdmF
	Local oCliAte
	Local oCliDe
	Local oCondPag
	Local oDiasAtr
	Local oRiscoCli
	Local oFormaPg
	Local oGrupCli
	Local oGrupPro
	Local oEmitenDe, oLojEmiDe, oEmitenAte, oLojEmiAte
	Local oLojaAte
	Local oLojaDe
	Local oMargDAb
	Local oMargDAc
	Local oMargMAb
	Local oMargMAc
	Local oPrecoAte
	Local oPrecoDe
	Local oProdAte
	Local oProdDe
	Local oRentAte
	Local oRentDe
	Local oGroup1
	Local oGroup2
	Local oGroup3
	Local oBtnCanc
	Local oBtnOk
	Local oRepFil
	Local oClasCli
	Local oSegCli
	Local oExcecao
	Local oPadrao
	Private oDlgFil

	DEFINE MSDIALOG oDlgFil TITLE "Atualiza Preço Negociação" FROM 000, 000  TO 554, 490 COLORS 0, 16777215 PIXEL

	@ 005, 005 GROUP oGroup1 TO 044, 242 PROMPT " Filtros de Produtos " OF oDlgFil COLOR 0, 16777215 PIXEL

	@ 015, 010 SAY oSay1 PROMPT "Produto De:" SIZE 037, 007 OF oDlgFil COLORS 0, 16777215 PIXEL
	@ 015, 125 SAY oSay2 PROMPT "Produto Até:" SIZE 034, 007 OF oDlgFil COLORS 0, 16777215 PIXEL
	@ 013, 059 MSGET oProdDe VAR cProdDe SIZE 065, 010 OF oDlgFil COLORS 0, 16777215 F3 "SB1DA1" HASBUTTON PIXEL
	@ 013, 173 MSGET oProdAte VAR cProdAte SIZE 065, 010 OF oDlgFil COLORS 0, 16777215 F3 "SB1DA1" HASBUTTON PIXEL

	@ 028, 010 SAY oSay3 PROMPT "Grupos Produto:" SIZE 050, 007 OF oDlgFil COLORS 0, 16777215 PIXEL
	@ 027, 059 MSGET oGrupPro VAR cGrupPro SIZE 180, 010 OF oDlgFil COLORS 0, 16777215 F3 "SBMMRK" HASBUTTON PIXEL

	@ 048, 005 GROUP oGroup2 TO 116, 242 PROMPT "      Exceção / Filtro de Cliente " OF oDlgFil COLOR 0, 16777215 PIXEL

	@ 048, 009 CHECKBOX oExcecao VAR lExcecao PROMPT "                                            " SIZE 75, 008 OF oDlgFil COLORS 0, 16777215 PIXEL

	@ 059, 010 SAY oSay5 PROMPT "Cliente/Loja De:" SIZE 044, 007 OF oDlgFil COLORS 0, 16777215 PIXEL
	@ 059, 125 SAY oSay6 PROMPT "Cliente Até:" SIZE 037, 007 OF oDlgFil COLORS 0, 16777215 PIXEL
	@ 057, 059 MSGET oCliDe VAR cCliDe SIZE 035, 010 OF oDlgFil COLORS 0, 16777215 F3 "SA1" HASBUTTON PIXEL
	@ 057, 099 MSGET oLojaDe VAR cLojaDe SIZE 015, 010 OF oDlgFil COLORS 0, 16777215 PIXEL
	@ 057, 174 MSGET oCliAte VAR cCliAte SIZE 035, 010 OF oDlgFil COLORS 0, 16777215 F3 "SA1" HASBUTTON PIXEL
	@ 057, 214 MSGET oLojaAte VAR cLojaAte SIZE 015, 010 OF oDlgFil COLORS 0, 16777215 PIXEL

	@ 073, 010 SAY oSay7 PROMPT "Grupos Cliente:" SIZE 037, 007 OF oDlgFil COLORS 0, 16777215 PIXEL
	@ 071, 059 MSGET oGrupCli VAR cGrupCli SIZE 180, 010 OF oDlgFil COLORS 0, 16777215 F3 "ACYMRK" HASBUTTON PIXEL

	@ 087, 010 SAY oSay7 PROMPT "Classe Cliente:" SIZE 050, 007 OF oDlgFil COLORS 0, 16777215 PIXEL
	@ 085, 059 MSGET oClasCli VAR cClasCli SIZE 065, 010 OF oDlgFil COLORS 0, 16777215 F3 "UF6MRK" HASBUTTON PIXEL
	@ 087, 125 SAY oSay7 PROMPT "Segmento Cli.:" SIZE 050, 007 OF oDlgFil COLORS 0, 16777215 PIXEL
	@ 085, 174 MSGET oSegCli VAR cSegCli SIZE 065, 010 OF oDlgFil COLORS 0, 16777215 F3 "T3MARK" HASBUTTON PIXEL

	@ 101, 010 SAY oSay9 PROMPT "Dias de Atraso:" SIZE 080, 007 OF oDlgFil COLORS 0, 16777215 PIXEL
	@ 099, 059 MSGET oDiasAtr VAR nDiasAtr SIZE 030, 010 OF oDlgFil COLORS 0, 16777215 PICTURE "999" HASBUTTON WHEN (!lExcecao)  PIXEL
	oDiasAtr:cTooltip := "(clientes com títulos vencidos a mais de (n) dias. Zero p/ ignorar)"
	oDiasAtr:lShowHint := .T.
	@ 101, 125 SAY oSay10 PROMPT "Risco Cliente:" SIZE 080, 007 OF oDlgFil COLORS 0, 16777215 PIXEL
	@ 099, 174 MSGET oRiscoCli VAR cRiscoCli SIZE 065, 010 OF oDlgFil COLORS 0, 16777215 F3 "ZVMARK" HASBUTTON PIXEL

	@ 121, 005 GROUP oGroup3 TO 256, 242 PROMPT " Filtros da Negociação " OF oDlgFil COLOR 0, 16777215 PIXEL

	@ 133, 010 SAY oSay11 PROMPT "Formas Pgto:" SIZE 044, 007 OF oDlgFil COLORS 0, 16777215 PIXEL
	@ 131, 059 MSGET oFormaPg VAR cFormaPg SIZE 180, 010 OF oDlgFil COLORS 0, 16777215 F3 "24MARK" HASBUTTON PIXEL

	@ 147, 010 SAY oSay13 PROMPT "Condições Pgto:" SIZE 047, 007 OF oDlgFil COLORS 0, 16777215 PIXEL
	@ 145, 059 MSGET oCondPag VAR cCondPg SIZE 180, 010 OF oDlgFil COLORS 0, 16777215 F3 "SE4MRK" HASBUTTON PIXEL

	@ 161, 010 SAY oSay14 PROMPT "Adm. Fin.:" SIZE 047, 007 OF oDlgFil COLORS 0, 16777215 PIXEL
	@ 159, 059 MSGET oAdmF VAR cAdmF SIZE 180, 010 OF oDlgFil COLORS 0, 16777215 F3 "SAEMRK" HASBUTTON PIXEL

	@ 175, 010 SAY oSay5 PROMPT "Emit.Cheque De:" SIZE 044, 007 OF oDlgFil COLORS 0, 16777215 PIXEL
	@ 175, 125 SAY oSay6 PROMPT "Emit.Cheque Até:" SIZE 044, 007 OF oDlgFil COLORS 0, 16777215 PIXEL
	@ 173, 059 MSGET oEmitenDe VAR cEmitenDe SIZE 035, 010 OF oDlgFil COLORS 0, 16777215 F3 "SA1CHQ" HASBUTTON PIXEL
	@ 173, 099 MSGET oLojEmiDe VAR cLojEmiDe SIZE 015, 010 OF oDlgFil COLORS 0, 16777215 PIXEL
	@ 173, 174 MSGET oEmitenAte VAR cEmitenAte SIZE 035, 010 OF oDlgFil COLORS 0, 16777215 F3 "SA1CHQ" HASBUTTON PIXEL
	@ 173, 214 MSGET oLojEmiAte VAR cLojEmiAte SIZE 015, 010 OF oDlgFil COLORS 0, 16777215 PIXEL

	@ 188, 010 SAY oSay15 PROMPT "Margem Mínima:" SIZE 042, 007 OF oDlgFil COLORS 0, 16777215 PIXEL
	@ 187, 059 CHECKBOX oMargMAb VAR lMargMAb PROMPT "Preços Abaixo" SIZE 060, 008 OF oDlgFil COLORS 0, 16777215 PIXEL
	@ 187, 125 CHECKBOX oMargMAc VAR lMargMAc PROMPT "Preços Acima" SIZE 060, 008 OF oDlgFil COLORS 0, 16777215 PIXEL

	@ 200, 010 SAY oSay19 PROMPT "Margem Desejada:" SIZE 048, 007 OF oDlgFil COLORS 0, 16777215 PIXEL
	@ 199, 059 CHECKBOX oMargDAb VAR lMargDAb PROMPT "Preços Abaixo" SIZE 060, 008 OF oDlgFil COLORS 0, 16777215 PIXEL
	@ 199, 125 CHECKBOX oMargDAc VAR lMargDAc PROMPT "Preços Acima" SIZE 060, 008 OF oDlgFil COLORS 0, 16777215 PIXEL

	@ 190, 174 SAY oSay15 PROMPT "Negociação Padrao?" SIZE 80, 007 OF oDlgFil COLORS 0, 16777215 PIXEL
	@ 198, 174 MSCOMBOBOX oPadrao VAR cPadrao ITEMS {"T=Todas","S=Apenas Padrão","N=Apenas Não Padrão"} SIZE 060, 008 OF oDlgFil COLORS 0, 16777215  PIXEL

	@ 213, 010 SAY oSay23 PROMPT "Rentabilidade De:" SIZE 048, 007 OF oDlgFil COLORS 0, 16777215 PIXEL
	@ 213, 097 SAY oSay24 PROMPT "%" SIZE 011, 007 OF oDlgFil COLORS 0, 16777215 PIXEL
	@ 213, 125 SAY oSay25 PROMPT "Rentabilidade Até:" SIZE 050, 007 OF oDlgFil COLORS 0, 16777215 PIXEL
	@ 213, 212 SAY oSay26 PROMPT "%" SIZE 011, 007 OF oDlgFil COLORS 0, 16777215 PIXEL
	@ 211, 059 MSGET oRentDe VAR nRentDe SIZE 025, 010 OF oDlgFil PICTURE "@E 999.99" COLORS 0, 16777215 HASBUTTON PIXEL
    @ 211, 174 MSGET oRentAte VAR nRentAte SIZE 025, 010 OF oDlgFil PICTURE "@E 999.99" COLORS 0, 16777215 HASBUTTON PIXEL

	@ 228, 010 SAY oSay27 PROMPT "Preço Neg. De:" SIZE 048, 007 OF oDlgFil COLORS 0, 16777215 PIXEL
	@ 228, 125 SAY oSay28 PROMPT "Preço Neg. Até:" SIZE 050, 007 OF oDlgFil COLORS 0, 16777215 PIXEL
	@ 226, 059 MSGET oPrecoDe VAR nPrecoDe SIZE 060, 010 OF oDlgFil PICTURE PesqPict("U25","U25_PRCVEN") COLORS 0, 16777215 HASBUTTON PIXEL
	@ 226, 174 MSGET oPrecoAte VAR nPrecoAte SIZE 060, 010 OF oDlgFil PICTURE PesqPict("U25","U25_PRCVEN") COLORS 0, 16777215 HASBUTTON PIXEL

	@ 243, 010 SAY oSay29 PROMPT "Desc/Acres De:" SIZE 048, 007 OF oDlgFil COLORS 0, 16777215 PIXEL
	@ 243, 125 SAY oSay30 PROMPT "Desc/Acres Até:" SIZE 050, 007 OF oDlgFil COLORS 0, 16777215 PIXEL
	@ 241, 059 MSGET oPrecoDe VAR nDesPbDe SIZE 060, 010 OF oDlgFil PICTURE PesqPict("U25","U25_DESPBA") COLORS 0, 16777215 HASBUTTON PIXEL
	@ 241, 174 MSGET oPrecoAte VAR nDesPbAte SIZE 060, 010 OF oDlgFil PICTURE PesqPict("U25","U25_DESPBA") COLORS 0, 16777215 HASBUTTON PIXEL

	if lWhenRepFil
		@ 262, 010 CHECKBOX oRepFil VAR lRepFil PROMPT "Replicar preços para outra Filial" SIZE 160, 008 OF oDlgFil COLORS 0, 16777215 PIXEL
	endif

	@ 259, 198 BUTTON oBtnOk PROMPT "Confirmar" SIZE 037, 012 OF oDlgFil ACTION iif(ValidFilt(),(lBotaoOk:=.T.,oDlgFil:End()),) PIXEL
	@ 259, 155 BUTTON oBtnCanc PROMPT "Cancelar" SIZE 037, 012 OF oDlgFil ACTION (lBotaoOk:=.F.,oDlgFil:End()) PIXEL

	ACTIVATE MSDIALOG oDlgFil CENTERED

	//Se quiser validar, aqui

Return lBotaoOk

Static Function ValidFilt()

	Local lRet := .T.

	if lMargMAb .AND. lMargMAc
		Help('',1,'HELP',,'Você deve selecionar margem mínima acima OU abaixo.',1,0)
		lRet := .F.
	endif

	if lMargDAb .AND. lMargDAc
		Help('',1,'HELP',,'Você deve selecionar margem desejada acima OU abaixo.',1,0)
		lRet := .F.
	endif

Return lRet
