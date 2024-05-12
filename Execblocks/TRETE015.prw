#include "protheus.ch"
#include "topconn.ch"

/*/{Protheus.doc} TRETE015
Ponto de Entrada para tratamento de manutencoes de bombas
@type function
@param cData Caractere - Data de intervencao
@param aTq Array - Array dos Grupos de Taques
@author Totvs TBC
@since 07/07/2014
@version 1.0
/*/

User Function TRETE015(cData,aTq)

Local cTexto	:=""
Local nI		:= 0
Local cTq 		:= ""

For nI := 1 To Len(aTq)

	If nI == Len(aTq)
		cTq += "'" + aTq[nI] + "'"
	Else
		cTq += "'" + aTq[nI] + "',"
	Endif
Next

if empty(cTq)
	cTq := "'xxx'"
endif

//1 busco as bombas dos tanques
cQry := "SELECT MIC_CODBOM, MIC_CODBIC"
cQry += " FROM "+RetSqlName("MIC")+""
cQry += " WHERE D_E_L_E_T_ = ''"
cQry += " AND MIC_FILIAL = '"+xFilial("MIC")+"'"
//cQry += " AND MIC_STATUS = '1'"
cQry += " AND ((MIC_STATUS = '1' AND MIC_XDTATI <= '"+cData+"') OR (MIC_STATUS = '2' AND MIC_XDTDES >= '"+cData+"')) "
cQry += " AND MIC_CODTAN IN ("+cTq+")"
cQry := ChangeQuery(cQry)

//MemoWrite("C:\TEMP\PCLRLMC1.TXT",cQry)
Tcquery cQry New alias 'PCLRLMC1'

_cManut := _cBomba := _cBicos:=''

//2 verifico se existe manutencao para cada bomba
While PCLRLMC1->(!Eof())

	cQry := "SELECT * FROM " +RetSqlName("U00")"
	cQry += " WHERE D_E_L_E_T_	= ''"
	cQry += " AND U00_FILIAL	= '"+xFilial("U00")+"'"
	cQry += " AND U00_BOMBA		= '"+PCLRLMC1->MIC_CODBOM+"'"
	cQry += " AND U00_DTINT		= '"+cData+"'"
	cQry := ChangeQuery(cQry)

	//MemoWrite("C:\TEMP\PCLRLMC1A.TXT",cQry)
	TcQuery cQry New alias "PCLRLMC1A"

	If !Empty(PCLRLMC1A->U00_BOMBA)

		_cManut := AllTrim(PCLRLMC1A->U00_NUMINT)
		_cBomba := AllTrim(PCLRLMC1A->U00_BOMBA)
		_cObs   := AllTrim(PCLRLMC1A->U00_MOTINT)

		//3 SE TIVER DADOS, DEVO AINDA BUSCAR OS BICOS QUE TIVERAM MANUTENCAO
		cQry := "SELECT U02_BICO"
		cQry += " FROM "+RetSqlName("U02")+""
		cQry += " WHERE D_E_L_E_T_	<>'*'"
		cQry += " AND U02_FILIAL	= '"+xFilial("U02")+"'"
		cQry += " AND U02_NUMSEQ	= '"+PCLRLMC1A->U00_NUMSEQ+"'"
		cQry += " AND U02_BICO		= '"+PCLRLMC1->MIC_CODBIC+"'"
		cQry := ChangeQuery(cQry)

		//MemoWrite("C:\TEMP\PCLRLMC1B.TXT",cQry)
		TcQuery cQry New Alias "PCLRLMC1B"

		If !Empty(PCLRLMC1B->U02_BICO)
			_cBicos += AllTrim(PCLRLMC1->MIC_CODBIC)+"-"
		Endif

		PCLRLMC1B->(DbCloseArea())
	Endif

	PCLRLMC1->(DbSkip())
	PCLRLMC1A->(DbCloseArea())
EndDo

If !Empty(_cManut)
	cTexto:="*Laudo Nr.:"+_cManut+",Bomba:"+_cBomba+",Bicos:"+_cBicos+ IIF(!Empty(_cObs),'Obs.'+_cObs+'*','*')
Endif

PCLRLMC1->(DbCloseArea())

Return cTexto
