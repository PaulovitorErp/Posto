#INCLUDE "PROTHEUS.CH"
#INCLUDE "TBICONN.CH"
#INCLUDE "PARMTYPE.CH"
#include "Topconn.ch"
#include "TbiCode.ch"

//--- 
//--- Preencher na SLI no campo LI_FUNC com o conteudo "_STGENERIC" e usar o campo LI_MSG em branco INCLUI ou preenchido ALTERACAO
//--- XXY devemos cadastrar a funcao XXX_ID = "_STGENERIC" e XXY_FUNC = "u_STGENERIC"
//--- XXZ devemos cadastrar a funcao XXZ_PROF = "MASTER" e XXZ_FUNC = "_STGENERIC"
//---
User Function STGeneric(aData)
Local lContinua := .F., lDecode := .F.
Local cAlias := "", cChave := "", cIndice := "", cLogICpo := "",  cLogACpo := ""
Local ix := 0, nPos := 0, nIndice := 0, nPos1 := 0, nPos2 := 0
Local aCampos := {}, cTime := Time()
Local aTamSx3

nPos := At("_",aData[01][01])
cAlias := Substr(aData[01][01],1,nPos-1)
cAlias := iif( len(cAlias) == 2, "S"+cAlias, cAlias)

LjGrvLog("STGeneric", 'INICIO - ALIAS: ' + cAlias)

//--- Buscar Campos de Indices
nPos := aScan(aData,{|x| "_XINDEX" $ AllTrim(x[01]) })
if nPos == 0 .or. aData[nPos][02] == 0
	nIndice	:= 1

else
	nIndice := iif( aData[nPos][02] > 0, aData[nPos][02], 1 )

endif

cIndice := AllTrim( (cAlias)->( IndexKey(nIndice) ) )
aCampos := StrTokArr( cIndice,"+")

for ix:=1 to len(aCampos)

	//--- Se for campo data devemos retirar o stod()
	if "DTOS(" $ aCampos[ix]
		aCampos[ix] := Substr(aCampos[ix],6, len(aCampos[ix])-1 )
	endif

	nPos := aScan(aData,{|x| AllTrim(x[01]) $ aCampos[ix] })
	if nPos > 0
              
		if ValType(aData[nPos][02]) == "D"
			cChave += dtos( aData[nPos][02] )

		elseif ValType(aData[nPos][02]) == "N"
			aTamSx3 := TamSX3(Alltrim(aData[nPos][02]))
			cChave += Str( aData[nPos][02], aTamSx3[1], aTamSx3[2] )

		else
			cChave += aData[nPos][02]

		endif

	endif

next ix

LjGrvLog("STGeneric", 'cChave: ' + cChave)

//--- Identificar se existe campos com caracteres especiais!!!
nPos := aScan(aData,{|x| "_USERLGI" $ AllTrim(x[01]) })
lDecode := nPos > 0

//--- Vamos verificar se o registro e para ser excluido!!!
nPos := aScan(aData,{|x| "_XSITUA" $ AllTrim(x[01]) })
if nPos > 0 .and. aData[nPos][02] == "E"

	//--- Funcao personalizada para excluir registros
	lContinua := ExcRegistro(cAlias , nIndice , cChave)

	LjGrvLog("STGeneric", 'ExcRegistro E: ' + iif(lContinua,".T.",".F."))

	Return lContinua

endif

//--- Vamos verificar se o registro e para ser excluido, usando o MSEXP!!!
nPos := aScan(aData,{|x| "_MSEXP" $ AllTrim(x[01]) })
if nPos > 0 .and. Alltrim(aData[nPos][02]) == "EXCLUI"

	//--- Funcao personalizada para excluir registros
	lContinua := ExcRegistro(cAlias , nIndice , cChave)
	
	LjGrvLog("STGeneric", 'ExcRegistro EXCLUI: ' + iif(lContinua,".T.",".F."))

	Return lContinua

endif

//--- Chama rotina padrao para inclusão/alteracao
lContinua := STDRecXData( cAlias , aData, .F., nIndice , cChave, lDecode)

LjGrvLog("STGeneric", 'STDRecXData - Inclusao/Alteracao: ' + iif(lContinua,".T.",".F."))

Return lContinua


//-----------------------------------------------
// REALIZA EXCLUSAO DE REGISTROS NA RETAGUARDA 
//-----------------------------------------------
Static Function ExcRegistro(cAlias , nIndice , cChave)
Local lRet := .F.

(cAlias)->( DbSetOrder(nIndice) )
if (cAlias)->( DbSeek( cChave ) )
	
	if RecLock(cAlias)
		(cAlias)->( DbDelete() )
		(cAlias)->( MsUnLock() )
		(cAlias)->( DbCommit() )
		lRet := .T.

	else
		//Conout("##### STDRecXData - Registro sem acesso exclusivo!! Tabela (" + cAlias + ") Chave: (" + cChave + ")" )

	endif

else
	//Conout("##### STDRecXData - Registro nao encontrado!! Tabela (" + cAlias + ") Chave: (" + cChave + ")" )

endif
Return lRet



//-- 
User Function xCarga()
Local cInterval := "300000", cIpType := "2", cLoadDel := "15"
Local ix := 0, xypo := 0
Local axFiliais := {}

Public cAcesso := "SSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSS"
Public cUsuario := "000000ADMIN"
Public cArqRel := "SIGAOMS.REL"
Public cArqEmp := "SIGAMAT.EMP"
Public aCBrowser := "xxxxxxxxxx"
Public cVersion := "11"
Public cModulo  := "LOJA"
Public nModulo  := 2
Public oMainWnd := {}
Public cPaisLoc := "BRA", cEstacao := "001"
Public lFlat := .T., lPanelFin := .T., lWsisPortal := .F., __lLogOff := .F., lLayaWay := .F.
Public dDataBase  := date()
Public cSupervisor := ""

Public cEmpAnt := "02", cFilAnt := "0101", cNivel := 9, cUserName := "Administrador", __cUserID := "000000"
Private cRegistros := "361563|362297"


LJCancNFCe( "01", "" )

QUIT

RpcSetType(3)
PREPARE ENVIRONMENT EMPRESA cEmpAnt FILIAL cFilAnt MODULO "LOJA"


QUIT
//-- Erro na L1_KEYNFCE
cSQL := "SELECT L1_FILIAL, L1_NUM, L1_DOC, L1_SERIE, L1_KEYNFCE, R_E_C_N_O_ NRRECNO "
cSQL += "FROM SL1020 "
cSQL += "WHERE D_E_L_E_T_ = ' ' AND L1_KEYNFCE LIKE '%www%' "


axFiliais := {}
aadd(axFiliais, {"0101","000004"} )
aadd(axFiliais, {"0201","000010"} )
aadd(axFiliais, {"0701","000018"} )

for xypo:=1 to 3

//-- Divergencia de chave L1_KEYNFCE com DOC_CHV
cSQL := "SELECT L1_FILIAL, L1_DOC, L1_EMISNF, L1_SERIE, NFE_ID, DOC_CHV, L1_KEYNFCE, SL1.R_E_C_N_O_ NRRECNO "
cSQL += "FROM SPED050 S50, SL1020 SL1 "
cSQL += "WHERE S50.D_E_L_E_T_ = ' '  AND SL1.D_E_L_E_T_ = ' ' "
cSQL += "AND ID_ENT = '" + axFiliais[xypo,2] + "' AND L1_FILIAL = '" + axFiliais[xypo,1] + "' "
cSQL += "AND NFE_ID = L1_SERIE + L1_DOC "
cSQL += "AND L1_KEYNFCE <> DOC_CHV "
cSQL += "AND SUBSTRING(DOC_CHV,1,3) <> 'Id=' "

//dbUseArea(.T.,"TOPCONN", TCGenQry(,,cSql), '_TBL', .F., .T.)
TcQuery cSQL New ALIAS "_TBL"
DbSelectArea("_TBL")

while !_TBL->( Eof() )

	do case 
	case _TBL->L1_FILIAL == '0101'
		cID := "000004"

	case _TBL->L1_FILIAL == '0201'
		cID := "000010"

	case _TBL->L1_FILIAL == '0701'
		cID := "000018"

	otherwise
		_TBL->( DbSkip() )
		Loop

	endcase

	cSql := "SELECT ID_ENT, DOC_CHV, NFE_ID "
	cSql += " FROM SPED050 "
	cSql += " WHERE D_E_L_E_T_ = ' ' AND ID_ENT = '" + cID + "' AND NFE_ID = '" + _TBL->L1_SERIE + _TBL->L1_DOC + "' "

	//dbUseArea(.T.,"TOPCONN", TCGenQry(,,cSql), '_S50', .F., .T.)
	TcQuery cSQL New ALIAS "_S50"
	if !_S50->( Eof() )
	
		SL1->( DbGoTo( _TBL->NRRECNO ) )
		RecLock("SL1")
			SL1->L1_KEYNFCE := _S50->DOC_CHV
		SL1->( MsUnLock() )		
	
		if SF2->( DbSetOrder(1), DbSeek( SL1->L1_FILIAL + SL1->L1_DOC + SL1->L1_SERIE ) )

			RecLock("SF2")
				SF2->F2_CHVNFE := _S50->DOC_CHV
			SF2->( MsUnLock() )
		
		endif	

		if SF3->( DbSetOrder(4), DbSeek( SL1->L1_FILIAL + SL1->L1_CLIENTE + SL1->L1_LOJA + SL1->L1_DOC + SL1->L1_SERIE ) )

			RecLock("SF3")
				SF3->F3_CHVNFE := _S50->DOC_CHV
			SF3->( MsUnLock() )
		
		endif			

		if SFT->( DbSetOrder(1), DbSeek( SL1->L1_FILIAL + "S" + SL1->L1_SERIE + SL1->L1_DOC + SL1->L1_CLIENTE + SL1->L1_LOJA  ) )

			while !SFT->( Eof() ) .and. (SL1->L1_FILIAL + "S" + SL1->L1_SERIE + SL1->L1_DOC + SL1->L1_CLIENTE + SL1->L1_LOJA) == ;
										(SFT->FT_FILIAL + SFT->FT_TIPOMOV + SFT->FT_SERIE + SFT->FT_NFISCAL + SFT->FT_CLIEFOR + SFT->FT_LOJA )

				RecLock("SFT")
					SFT->FT_CHVNFE := _S50->DOC_CHV
				SFT->( MsUnLock() )
				
				SFT->( DbSkip() )
				
				lret := .F.
				if lRet
					QUIT
				endif

			enddo
		
		endif
	
	endif

	_S50->( DbCloseArea() )

	_TBL->( DbSkip() )

enddo
_TBL->( DbCloseArea() )

next xypo
QUIT


//STWUpData("02","0101")
QUIT


lMDI := .F.

RpcSetType(3)
PREPARE ENVIRONMENT EMPRESA cEmpAnt FILIAL cFilAnt MODULO "LOJA"

//-- Se nao existir tags, significa que o TSS nao esta instalado
cServerIni := GetAdv97()
cIP	:= GetPvProfString("TSSOFFLINE", "IP"	, ""	, cServerIni)

if Empty(cIP)
	//Conout('STDSpedForUp: STDGrvSpeds -> Favor realizar a configuracao das tags para replicacao das informacoes SPED -> STDGrvSpeds')
	Return .F.
endif
	
//-- Guarda a ID conexao atual
nHndAtual := AdvConnection()
	
//-- Carrega Informacoes do Appserver.ini
cPorta 	:= GetPvProfString("TSSOFFLINE", "PORTA"	, ""	, cServerIni)
cApelido:= GetPvProfString("TSSOFFLINE", "ALIAS"	, ""	, cServerIni)
cBanco 	:= GetPvProfString("TSSOFFLINE", "BANCO"	, ""	, cServerIni)

TcConType("TCPIP")
nHndDb := TcLink( "@!!@"+cBanco+"/"+cApelido, cIP, Val(cPorta) )
TcInternal( 12, 'ON' )
	
if nHndDb < 0 
	//Conout('STDSpedForUp: STDGrvSpeds -> Erro ao conectar com ' + cApelido + " em " + 'cBanco com DbAccess -> STDGrvSpeds')
	Return .F.
endif

//-- Ativa a Conex? ao Banco do TSS
TCSETCONN( nHndDb )



aNotas := {}

/*
aadd(anotas, "############ NF 0201:1  000164652 NAO LOCALIZADA NA SPED050 COM STATUS TRANSMITIDA #") 
aadd(anotas, "############ NF 0201:1  000164653 NAO LOCALIZADA NA SPED050 COM STATUS TRANSMITIDA #") 
aadd(anotas, "############ NF 0201:1  000164654 NAO LOCALIZADA NA SPED050 COM STATUS TRANSMITIDA #") 
aadd(anotas, "############ NF 0201:1  000164655 NAO LOCALIZADA NA SPED050 COM STATUS TRANSMITIDA #") 

aadd(anotas, "############ NF 0301:1  000051315 NAO LOCALIZADA NA SPED050 COM STATUS TRANSMITIDA #") 
aadd(anotas, "############ NF 0301:1  000051317 NAO LOCALIZADA NA SPED050 COM STATUS TRANSMITIDA #") 
aadd(anotas, "############ NF 0301:1  000051383 NAO LOCALIZADA NA SPED050 COM STATUS TRANSMITIDA #") 
aadd(anotas, "############ NF 0301:1  000051384 NAO LOCALIZADA NA SPED050 COM STATUS TRANSMITIDA #") 
aadd(anotas, "############ NF 0301:1  000051673 NAO LOCALIZADA NA SPED050 COM STATUS TRANSMITIDA #") 
aadd(anotas, "############ NF 0301:1  000052053 NAO LOCALIZADA NA SPED050 COM STATUS TRANSMITIDA #") 
aadd(anotas, "############ NF 0301:1  000052122 NAO LOCALIZADA NA SPED050 COM STATUS TRANSMITIDA #")

aadd(aNotas, "############ NF 0401:1  000320845 NAO LOCALIZADA NA SPED050 COM STATUS TRANSMITIDA ############# ")
aadd(aNotas, "############ NF 0401:1  000320867 NAO LOCALIZADA NA SPED050 COM STATUS TRANSMITIDA ############# ")
aadd(aNotas, "############ NF 0401:1  000321031 NAO LOCALIZADA NA SPED050 COM STATUS TRANSMITIDA ############# ")
aadd(aNotas, "############ NF 0401:1  000321545 NAO LOCALIZADA NA SPED050 COM STATUS TRANSMITIDA ############# ")
aadd(aNotas, "############ NF 0401:1  000321947 NAO LOCALIZADA NA SPED050 COM STATUS TRANSMITIDA ############# ")
aadd(aNotas, "############ NF 0401:1  000322010 NAO LOCALIZADA NA SPED050 COM STATUS TRANSMITIDA ############# ")
aadd(aNotas, "############ NF 0401:1  000322134 NAO LOCALIZADA NA SPED050 COM STATUS TRANSMITIDA ############# ")
aadd(aNotas, "############ NF 0401:1  000322223 NAO LOCALIZADA NA SPED050 COM STATUS TRANSMITIDA ############# ")
aadd(aNotas, "############ NF 0401:1  000322445 NAO LOCALIZADA NA SPED050 COM STATUS TRANSMITIDA ############# ")
aadd(aNotas, "############ NF 0401:1  000322934 NAO LOCALIZADA NA SPED050 COM STATUS TRANSMITIDA ############# ")
aadd(aNotas, "############ NF 0401:1  000322948 NAO LOCALIZADA NA SPED050 COM STATUS TRANSMITIDA ############# ")
aadd(aNotas, "############ NF 0401:1  000323121 NAO LOCALIZADA NA SPED050 COM STATUS TRANSMITIDA ############# ")
aadd(aNotas, "############ NF 0401:1  000323120 NAO LOCALIZADA NA SPED050 COM STATUS TRANSMITIDA ############# ")

aadd(aNotas, "############ NF 0402:1  000274703 NAO LOCALIZADA NA SPED050 COM STATUS TRANSMITIDA ############# ")
aadd(aNotas, "############ NF 0402:1  000274967 NAO LOCALIZADA NA SPED050 COM STATUS TRANSMITIDA ############# ")
aadd(aNotas, "############ NF 0402:1  000275380 NAO LOCALIZADA NA SPED050 COM STATUS TRANSMITIDA ############# ")
aadd(aNotas, "############ NF 0402:1  000275544 NAO LOCALIZADA NA SPED050 COM STATUS TRANSMITIDA ############# ")
aadd(aNotas, "############ NF 0402:1  000275545 NAO LOCALIZADA NA SPED050 COM STATUS TRANSMITIDA ############# ")
aadd(aNotas, "############ NF 0402:1  000275586 NAO LOCALIZADA NA SPED050 COM STATUS TRANSMITIDA ############# ")
aadd(aNotas, "############ NF 0402:1  000275699 NAO LOCALIZADA NA SPED050 COM STATUS TRANSMITIDA ############# ")
aadd(aNotas, "############ NF 0402:1  000275785 NAO LOCALIZADA NA SPED050 COM STATUS TRANSMITIDA ############# ")
aadd(aNotas, "############ NF 0402:1  000275884 NAO LOCALIZADA NA SPED050 COM STATUS TRANSMITIDA ############# ")
aadd(aNotas, "############ NF 0402:1  000275949 NAO LOCALIZADA NA SPED050 COM STATUS TRANSMITIDA ############# ")
aadd(aNotas, "############ NF 0402:1  000276172 NAO LOCALIZADA NA SPED050 COM STATUS TRANSMITIDA ############# ")
aadd(aNotas, "############ NF 0402:1  000276223 NAO LOCALIZADA NA SPED050 COM STATUS TRANSMITIDA ############# ")
aadd(aNotas, "############ NF 0402:1  000276375 NAO LOCALIZADA NA SPED050 COM STATUS TRANSMITIDA ############# ")
aadd(aNotas, "############ NF 0402:1  000276383 NAO LOCALIZADA NA SPED050 COM STATUS TRANSMITIDA ############# ")
aadd(aNotas, "############ NF 0402:1  000276449 NAO LOCALIZADA NA SPED050 COM STATUS TRANSMITIDA ############# ")
aadd(aNotas, "############ NF 0402:1  000276475 NAO LOCALIZADA NA SPED050 COM STATUS TRANSMITIDA ############# ")
aadd(aNotas, "############ NF 0402:1  000276518 NAO LOCALIZADA NA SPED050 COM STATUS TRANSMITIDA ############# ")
aadd(aNotas, "############ NF 0402:1  000276667 NAO LOCALIZADA NA SPED050 COM STATUS TRANSMITIDA ############# ")
aadd(aNotas, "############ NF 0402:1  000276743 NAO LOCALIZADA NA SPED050 COM STATUS TRANSMITIDA ############# ")
aadd(aNotas, "############ NF 0402:1  000276880 NAO LOCALIZADA NA SPED050 COM STATUS TRANSMITIDA ############# ")

aadd(aNotas, "############ NF 0601:1  000006750 NAO LOCALIZADA NA SPED050 COM STATUS TRANSMITIDA ############# ")
aadd(aNotas, "############ NF 0601:1  000007068 NAO LOCALIZADA NA SPED050 COM STATUS TRANSMITIDA ############# ")
aadd(aNotas, "############ NF 0601:1  000006750 NAO LOCALIZADA NA SPED050 COM STATUS TRANSMITIDA ############# ")

aadd(aNotas, "############ NF 9601:1  000006460 NAO LOCALIZADA NA SPED050 COM STATUS TRANSMITIDA ############# ")
aadd(aNotas, "############ NF 9601:1  000006372 NAO LOCALIZADA NA SPED050 COM STATUS TRANSMITIDA ############# ")
aadd(aNotas, "############ NF 9601:1  000006602 NAO LOCALIZADA NA SPED050 COM STATUS TRANSMITIDA ############# ")
aadd(aNotas, "############ NF 9601:1  000006631 NAO LOCALIZADA NA SPED050 COM STATUS TRANSMITIDA ############# ")
aadd(aNotas, "############ NF 9601:1  000006635 NAO LOCALIZADA NA SPED050 COM STATUS TRANSMITIDA ############# ")
aadd(aNotas, "############ NF 9601:1  000006372 NAO LOCALIZADA NA SPED050 COM STATUS TRANSMITIDA ############# ")
aadd(aNotas, "############ NF 9601:1  000006460 NAO LOCALIZADA NA SPED050 COM STATUS TRANSMITIDA ############# ")
aadd(aNotas, "############ NF 9601:1  000006602 NAO LOCALIZADA NA SPED050 COM STATUS TRANSMITIDA ############# ")
aadd(aNotas, "############ NF 9601:1  000006631 NAO LOCALIZADA NA SPED050 COM STATUS TRANSMITIDA ############# ")
aadd(aNotas, "############ NF 9601:1  000006635 NAO LOCALIZADA NA SPED050 COM STATUS TRANSMITIDA ############# ")
 
aadd(anotas, "############ NF 0801:1  000006415 NAO LOCALIZADA NA SPED050 COM STATUS TRANSMITIDA #") 
*/

aadd(anotas, "############ NF 0101:4  000014665 NAO LOCALIZADA NA SPED050 COM STATUS TRANSMITIDA #############")
aadd(anotas, "############ NF 0101:4  000014667 NAO LOCALIZADA NA SPED050 COM STATUS TRANSMITIDA #############")
aadd(anotas, "############ NF 0101:4  000014671 NAO LOCALIZADA NA SPED050 COM STATUS TRANSMITIDA #############")
aadd(anotas, "############ NF 0101:4  000014707 NAO LOCALIZADA NA SPED050 COM STATUS TRANSMITIDA #############")
aadd(anotas, "############ NF 0101:4  000014710 NAO LOCALIZADA NA SPED050 COM STATUS TRANSMITIDA #############")
aadd(anotas, "############ NF 0101:4  000014722 NAO LOCALIZADA NA SPED050 COM STATUS TRANSMITIDA #############")
aadd(anotas, "############ NF 0101:4  000014740 NAO LOCALIZADA NA SPED050 COM STATUS TRANSMITIDA #############")
aadd(anotas, "############ NF 0101:4  000014741 NAO LOCALIZADA NA SPED050 COM STATUS TRANSMITIDA #############")
aadd(anotas, "############ NF 0101:4  000014748 NAO LOCALIZADA NA SPED050 COM STATUS TRANSMITIDA #############")
aadd(anotas, "############ NF 0101:4  000014664 NAO LOCALIZADA NA SPED050 COM STATUS TRANSMITIDA #############")
aadd(anotas, "############ NF 0101:4  000014518 NAO LOCALIZADA NA SPED050 COM STATUS TRANSMITIDA #############")
aadd(anotas, "############ NF 0101:4  000014522 NAO LOCALIZADA NA SPED050 COM STATUS TRANSMITIDA #############")
aadd(anotas, "############ NF 0101:4  000014522 NAO LOCALIZADA NA SPED050 COM STATUS TRANSMITIDA #############")
aadd(anotas, "############ NF 0101:4  000014624 NAO LOCALIZADA NA SPED050 COM STATUS TRANSMITIDA #############")
aadd(anotas, "############ NF 0101:4  000014657 NAO LOCALIZADA NA SPED050 COM STATUS TRANSMITIDA #############")

/*
aIDs := { {"0101","000004"},;
  		  {"0201","000010"},;
		  {"0301","000001"},;
		  {"0401","000002"},;
		  {"0402","000002"},;
		  {"0601","000002"},;
		  {"0801","000020"},;
  		  {"9601","000021"} }
*/


aIDs := { {"0101","000001"},;
		  {"0301","000001"},;
  		  {"0201","000001"},;
  		  {"0801","000001"} }


for ix:=1 to len(aNotas)

	nPos := aScan(aIDs,{|x| x[1] == Substr(aNotas[ix],17,04) } )
    if nPos == 0
    	Loop
    endif

	cSql := "SELECT * FROM SPED050 "
	cSql += " WHERE NFE_ID = '" + Substr(aNotas[ix],22,12) + "' AND ID_ENT = '"	+ aIDs[nPos][02] + "' "
	cSql += " ORDER BY R_E_C_N_O_ DESC "

	//dbUseArea(.T.,"TOPCONN", TCGenQry(,,cSql), '_TBL', .F., .T.)
	TcQuery cSQL New ALIAS "_TBL"

	if !_TBL->( Eof() )
     
     	cSql := "UPDATE SPED050 SET SITUA = ' ' WHERE R_E_C_N_O_ = '" + AllTrim( Str(_TBL->R_E_C_N_O_) ) + "' "
     	TCSQLEXEC(cSql)
     
	endif

	_TBL->( DbCloseArea() )

next ix

//aOrcs  := StrToKarr(cRegistros,"|")
//nQuant := Len(aOrcs)
//nRet := FRTExclusa( aOrcs[1], "" )
//LJCancNFCe( "02", "0701" )
//QUIT

//u_STDSpedForUp()

QUIT
