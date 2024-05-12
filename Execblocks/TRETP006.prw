#include "Protheus.ch"
#include "rwmake.ch"
#include "topconn.ch"
#Include "SigaWin.ch"

/*/{Protheus.doc} TRETP006
CHAMADO PELO P.E. MT100TOK NA CLASSIFICACAO DA PRE-NOTA PARA VALIDAR SE PEDIDO
DE COMPRA TEM OU NAO UM CRC ENCERRADO-COMBUSTIVEL/POSTO
@author Totvs TBC
@since 05/12/2013
@version 1.0

@type function
/*/

User Function TRETP006()

local _lret  	:= Paramixb[1]
Local lCrc := SuperGetMv("MV_XTPCRC",.F.,.T.) //habilita CRC
Local cMVCombus := AllTrim(SuperGetMv("MV_XCOMBUS",,"")) //Somente combustiveis: GASOLINA, ETANOL e DIESEL
Local cQry		:= ""
Local nI, nZ

Local lMvPosto := SuperGetMv("MV_XPOSTO",.F.,.F.) //Habilita Posto de Combustível (Posto Inteligente).
//Caso o Posto Inteligente não esteja habilitado não faz nada...
If !lMvPosto
	Return _lRet
EndIf

If 'MATA103'$FUNNAME() //Claudio Ferreira 30.05.15  Estava chamando na inutilizacao.  
 	
	lMT100TOK := .F. //o ponto de entrada será chamado somente uma vez  
	nPosPro := aScan(aHEADER,{|x| Trim(x[2])=="D1_COD"})    
	nPoscrc := aScan(aHEADER,{|x| Trim(x[2])=="D1_XCRC"})

	If lCrc .AND. cTipo <> "D" // se a nota não for de devoluçao
		For nZ:=1 to len(acols) // SD1->D1_GRUPO==getmv("MV_XGRPC").AND.Empty(SD1->D1_XCRC)
			_lProd := Posicione("SB1",1,xFilial("SB1")+aCols[nZ,nPosPro],"B1_GRUPO") $ cMVCombus     
			If _lProd .and. aCols[nZ,Len(aHeader)+1] == .F. 
				If Empty(aCols[nZ,nPoscrc])
					MsgInfo("Item: "+AllTrim(Str(nZ))+" da Nota Fiscal nao Amarrado a um CRC!","ERRO CLASSIFICACAO PROD. COMBUSTIVEL")
					_lRet:=.F. 
				Else
					// verifico se o CRC é válido
					ZE3->(DbSetOrder(1)) // ZE3_FILIAL + ZE3_NUMERO 
					If ZE3->(DbSeek(xFilial("ZE3") + aCols[nZ,nPoscrc])) 
						If ZE3->ZE3_STATUS <> "2" // se o CRC não estiver aprovado
							MsgInfo("Item: " + AllTrim(Str(nZ)) + " da Nota Fiscal nao Amarrado a um CRC aprovado!","ERRO CLASSIFICACAO PROD. COMBUSTIVEL")
							_lRet:=.F. 
						EndIf
					EndIf				
				EndIf
			EndIf  
		Next nZ    
	EndIf
	
	//Validação LMC
	If _lRet
		For nI := 1 To Len(aCols)
			_lProd := Posicione("SB1",1,xFilial("SB1")+aCols[nI,nPosPro],"B1_GRUPO") $ cMVCombus //Quintais  
			If aCols[nI,Len(aHeader)+1] == .F. .AND. _lProd
				
				If Select("QRYLMC") > 0
					QRYLMC->(DbCloseArea())
				EndIf
				
				cQry := "SELECT MIE_DATA"
				cQry += " FROM "+RetSqlName("MIE")+""
				cQry += " WHERE D_E_L_E_T_ 	<> '*'"
				cQry += " AND MIE_FILIAL 	= '"+xFilial("MIE")+"'"
				cQry += " AND MIE_DATA		= '"+DToS(dDataBase)+"'" //dDemissao
				cQry += " AND MIE_CODPRO	= '"+aCols[nI][nPosPro]+"'"
				
				cQry := ChangeQuery(cQry)
				//MemoWrite("c:\temp\A100DEL.txt",cQry)
				TcQuery cQry NEW Alias "QRYLMC"
				
				If QRYLMC->(!EOF())
					MsgInfo("Existe página LMC gerada para o produto <"+AllTrim(aCols[nI][nPosPro])+"> nessa data, operação de inclusão não permitida.","Atenção")
					_lRet := .F.
					Exit
				EndIf
			EndIf
		Next nI
		
		If Select("QRYLMC") > 0
			QRYLMC->(DbCloseArea())
		EndIf
	EndIf

EndIf

Return _lRet
