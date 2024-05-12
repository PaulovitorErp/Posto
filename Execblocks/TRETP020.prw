#include 'protheus.ch'
#include 'parmtype.ch'
    
/*/{Protheus.doc} TRETP020 (FA070TIT)
O ponto de entrada FA070TIT sera executado apos a confirmacao da baixa do contas a receber.
USO: alçada de desconto sobre titulos

@author Totvs TBC
@since 25/10/2015
@version 1.0
@return ${return}, ${return_description}
@type function
/*/
User function TRETP020()

    Local lRet := .T.
    Local lAlcada	:= SuperGetMv("ES_ALCADA",.F.,.F.)
    Local lAlcDTIT	:= SuperGetMv("ES_ALCDTIT",.F.,.F.)
	Local nPercDesc := 0

	Local lMvPosto := SuperGetMv("MV_XPOSTO",.F.,.F.) //Habilita Posto de Combustível (Posto Inteligente).
	//Caso o Posto Inteligente não esteja habilitado não faz nada...
	If !lMvPosto
		Return lRet
	EndIf

	Private aLogAlcada := {}

    If !IsBlind() //se nao for rotina automatica
        
        //VALIDAÇÃO ALCADA DESCONTOS
        //Variaveis Private disponíveis;
        //nDescont - Descontos
        //nDecresc - Decrescimos; 
        //nValPadrao - Valor a ser liquidado do titulo (pode ser parcial)
        If lAlcada .And. lAlcDTIT .AND. (nDescont+nDecresc) > 0

            //obtendo percentual de desconto aplicado
            nPercDesc := (nDescont+nDecresc) / nValPadrao * 100

            lRet := LibAlcadaDes(,nPercDesc) //verifico alçada do prorio usuario
            if !lRet
                lRet := TelaLibAlcada(nPercDesc)
			endif
				
			U_TR037LCE(aLogAlcada[1][1], aLogAlcada[1][2], SE1->E1_FILIAL+SE1->E1_PREFIXO+SE1->E1_NUM+SE1->E1_PARCELA+SE1->E1_TIPO , aLogAlcada[1][3])

        EndIf
        
    EndIf

return lRet

Static Function LibAlcadaDes(cCodUsr, nPercDesc)

	Local nZ
	Local lRet := .F.
	Local nVlrMaxDesc := 0
	Local cMsgLog 
	Default cCodUsr := RetCodUsr()

	cMsgLog := "Alçada Desconto sobre Titulos." + CRLF
	cMsgLog += "Valor do Titulo: " + cValToChar(SE1->E1_VALOR) + CRLF
	cMsgLog += "Valor a ser Liquidado: " + cValToChar(nValPadrao) + CRLF
	cMsgLog += "Valor Desconto+Decrescimo: " + cValToChar(nDescont+nDecresc) + CRLF
	cMsgLog += "% Total Descontos: " + cValToChar(nPercDesc) + " %" + CRLF

	If cCodUsr == '000000' //usuario administrador, libera tudo
		lRet := .T.
		cMsgLog += "Usuário Liberação: " + cCodUsr + " - " + USRRETNAME(cCodUsr) + CRLF
	else
		aGrupos := UsrRetGrp(UsrRetName(cCodUsr), cCodUsr)

		nVlrMaxDesc := Posicione("U0D",1,xFilial("U0D")+Space(TamSx3("U04_GRUPO")[1])+PadR(cCodUsr,TamSx3("U04_USER")[1]),"U0D_PDESCT")
		if nVlrMaxDesc >= nPercDesc
			lRet := .T.
			cMsgLog += "Usuário Liberação: " + cCodUsr + " - " + USRRETNAME(cCodUsr) + CRLF
		endif

		if !lRet
			for nZ := 1 to len(aGrupos)
				nVlrMaxDesc := Posicione("U0D",1,xFilial("U0D")+PadR(aGrupos[nZ],TamSx3("U04_GRUPO")[1])+Space(TamSx3("U04_USER")[1]),"U0D_PDESCT")
				if nVlrMaxDesc >= nPercDesc
					lRet := .T.
					cMsgLog += "Grupo de Usuário Liberação: " + aGrupos[nZ] + " - " + GrpRetName(aGrupos[nZ]) + CRLF
					EXIT
				endif
			next nZ
		endif
	endif

	//para gravaçao do log alçada
	if lRet
		cMsgLog += "% Desc. Titulo Alçada: " + cValToChar(nVlrMaxDesc) +" %"+ CRLF
		aadd(aLogAlcada, {"ALCDTI", USRRETNAME(cCodUsr), cMsgLog})
	endif

Return lRet

Static Function TelaLibAlcada(nPercDesc)
    
    Local cQuebra := chr(13)+chr(10)
	Local lRet := .F.
	Local lEscape := .T.
    Local cMsgErr := "Desconto acima do permitido!"+cQuebra
    Local cMsgUsr := ""
	Local aLogin

    cMsgErr += "Valor a Liquidar: " + Alltrim(Transform(nValPadrao, PesqPict("SE1","E1_VALOR"))) +cQuebra
    cMsgErr += "Total Descontos: " + Alltrim(Transform((nDescont+nDecresc), PesqPict("SE1","E1_VALOR"))) +cQuebra
    cMsgErr += "Desconto de: " + Alltrim(Transform(nPercDesc, PesqPict("SE1","E1_VALOR"))) +" %"+cQuebra
    cMsgErr += "Solicite liberação por alçada de um supervisor."

	While lEscape
		aLogin := U_TelaLogin(cMsgUsr+cMsgErr,"Bloqueio de Desconto", .T.)
		if empty(aLogin) //cancelou tela
			lEscape := .F.
		else
			lRet := LibAlcadaDes(aLogin[1], nPercDesc)
			if !lRet
				cMsgUsr := "Usuário "+Alltrim(aLogin[2])+" não possui alçada suficiente para liberar o desconto!"+cQuebra
			endif
			lEscape := !lRet
		endif
	enddo

Return lRet
