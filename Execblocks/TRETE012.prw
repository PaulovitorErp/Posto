#include 'protheus.ch'
#include 'fwmvcdef.ch'

/*/{Protheus.doc} TRETE012
Reprocessa ganho e perda LMC
@author Maiki Perin
@since 08/11/2018
@version 1.0
@param cCampo
@return nulo
/*/

/***************************/
User Function TRETE012(nOri)
/***************************/
	
Local lRet			:= .T.

Local oModel	 	:= FWModelActive()
Local nOperation	:= oModel:GetOperation()
Local oModelMIE  	:= oModel:GetModel("MIEMASTER")
Local oView			:= FWViewActive()

Local nPercVar 		:= SuperGetMv("MV_XPERCGP",,0.6) / 100 //Define o percentual para perdas e sobras no LMC

Local nEstFec		:= 0
Local nNewEstFec	:= 0

Local nAuxGanho		:= 0
Local nAuxPerda		:= 0 
Local nI 
Local nQTQLMC := SuperGetMv("MV_XQTQLMC",,20) //Quantidade de tanques para apura��o LMC

Local lLmcKard		:= SuperGetMV("MV_XLMCKAR",,.F.) //habilita ajuste perda ou ganho pelo kardex
Local nLimKard		:= SuperGetMv("MV_XLMCLKA",,1)  //limite em litros para diferen�a do kardex e estoque escritural
Local cUsrCmp		:= ""

//Valida Estoque de Fechamento negativo
For nI := 1 To nQTQLMC
	if MIE->(FieldPos( 'MIE_VTAQ'+StrZero(nI,2) ))>0
		If oModelMIE:GetValue('MIE_VTAQ' + StrZero(nI,2)) < 0
			
			Help( ,, 'Help - GeraLMC',, 'O valor de fechamento Est Final '+StrZero(nI,2)+', se encontra negativo, situa��o n�o permitida.', 1, 0 )
			Return .F.
		Endif
	endif
Next

If nOperation == 3 //Inclus�o
	For nI := 1 To Len(__aEstFec)
		nEstFec += __aEstFec[nI][2] //__aEstFec[nI][1]
    Next
Else
	For nI := 1 To nQTQLMC
		if MIE->(FieldPos( 'MIE_VTAQ'+StrZero(nI,2) ))>0
			nEstFec += oModelMIE:GetValue('MIE_VTAQ'+StrZero(nI,2) )
		endif
	next nI
Endif

nAuxGanho := nEstFec + (nEstFec * nPercVar)
nAuxPerda := nEstFec - (nEstFec * nPercVar)

For nI := 1 To nQTQLMC
	if MIE->(FieldPos( 'MIE_VTAQ'+StrZero(nI,2) ))>0
		nNewEstFec += oModelMIE:GetValue('MIE_VTAQ'+StrZero(nI,2) )
	endif
next nI

//atualiza��o dados tela
If nOri == 0                

	if nNewEstFec <> nEstFec
		if nNewEstFec > nEstFec //teve ganho
			oModelMIE:SetValue('MIE_PERDA',0)
			oModelMIE:SetValue('MIE_GANHOS',nNewEstFec - nEstFec)
		else //teve perda
			oModelMIE:SetValue('MIE_PERDA',nEstFec - nNewEstFec)
			oModelMIE:SetValue('MIE_GANHOS',0)
		endif
	endif

	oModelMIE:SetValue('MIE_ESTFEC',nNewEstFec)
	
	If MIE->(FieldPos("MIE_XPERGP")) > 0
		oModelMIE:SetValue('MIE_XPERGP',Abs(((nNewEstFec - nEstFec) / nEstFec) * 100))
	Endif
Endif

//Valida��o 
If nNewEstFec > nAuxGanho .Or. nNewEstFec < nAuxPerda
	If nOri == 1

		If cNivel < 9
			//cadastra rotina para controle de acesso
			U_TRETA37B("MIEDLM", "ULTRAPASSAR LIMITE DE ESTOQUE DE FECHAMENTO: MV_XPERCGP")
			
			//verifica se o usu�rio tem permiss�o para acesso a rotina
			cUsrCmp := U_VLACESS1("MIEDLM", RetCodUsr())
		EndIf

		If !(cUsrCmp == Nil .OR. Empty(cUsrCmp)) .or. cNivel == 9
			If !MsgYesNo("O valor digitado ultrapassa o limite de "+cValToChar(nPercVar * 100)+"% de varia��o no Estoque de Fechamento, deseja continuar?","Aten��o")
				lRet := .F.
			Endif
		Else
			Help( ,, 'Help - GeraLMC',, 'O valor digitado ultrapassa o limite de '+cValToChar(nPercVar * 100)+'% de varia��o no Estoque de Fechamento, opera��o n�o permitida.', 1, 0 )
			lRet := .F.
		Endif		
	Endif
Endif

if lRet .AND. GetSx3Cache('MIE_XKARDE',"X3_TIPO")=="N" .AND. lLmcKard 
	if oModelMIE:GetValue('MIE_XKARDE') <= 0
		Help( ,, 'Help - GeraLMC',, 'Habilitado ajuste Perda/Ganho Pelo Kardex e o valor obtido do Kardex se encontra zerado ou negativo. Situa��o n�o permitida.', 1, 0 )
		lRet := .F.
	endif
	if lRet .AND. Abs(oModelMIE:GetValue('MIE_XKARDE') - oModelMIE:GetValue('MIE_ESTESC')) > nLimKard

		If cNivel < 9
			//cadastra rotina para controle de acesso
			U_TRETA37B("MIEDLM", "ULTRAPASSAR LIMITE DE ESTOQUE DE FECHAMENTO: MV_XPERCGP")
			
			//verifica se o usu�rio tem permiss�o para acesso a rotina
			cUsrCmp := U_VLACESS1("MIEDLM", RetCodUsr())
		EndIf

		If !(cUsrCmp == Nil .OR. Empty(cUsrCmp)) .or. cNivel == 9
			If !MsgYesNo("A diferen�a entre Kardex e Estoque Escritural ultrapassa o limite de "+cValtoChar(nLimKard)+" litro(s) de varia��o! deseja continuar?","Aten��o")
				lRet := .F.
			Endif
		Else
			Help( ,, 'Help - GeraLMC',, 'A diferen�a entre Kardex e Estoque Escritural ultrapassa o limite de '+cValtoChar(nLimKard)+' litro(s) de varia��o! opera��o n�o permitida. (MV_XLMCLKA)', 1, 0 )
			lRet := .F.
		Endif
	endif
endif

If lRet
	oView:Refresh()
Endif

Return lRet
