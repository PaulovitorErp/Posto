#include 'protheus.ch'
#include 'parmtype.ch'
/*/{Protheus.doc} TPDVP018 (STEXITPOS)
Valida��o para sair da tela PDV

@author thebr
@since 29/05/2019
@version 1.0
@return lRet
@type function
/*/
User Function TPDVP018()

	//Fun��o padrao (fonte STFExit) para pegar se pode ou nao sair
	Local lRet      := STFGetPerExit() //ParamIxb
	Local lOpenCash := STBOpenCash() // Verifico se o caixa esta aberto - Felipe Sousa 23/02/2024
	Local lClsSys   := SuperGetMv("TP_EXITSYS",,.F.)

	Local lMvPosto := SuperGetMv("MV_XPOSTO",.F.,.F.) //Habilita Posto de Combust�vel (Posto Inteligente).
	//Caso o Posto Inteligente n�o esteja habilitado n�o faz nada...
	If !lMvPosto
		Return lRet
	EndIf

	//Limpar Tela (SHIFT+F3), evitar de abastecimentos ficarem presos...
	//Ticket: POSTO-741 - Abastecimentos retornam pra tela - Sereia - 17/02/23
	//DANILO: COMENTADO POIS ESTA DANDO ERRORLOG AO SAIR
	//If !SuperGetMV("MV_LJPLNAB", ,.F.) .AND. !(U_TPDVP02A())
	//	Return .F.
	//EndIf

	If lRet 
		//limpo a��o teclas atalho, setada no PE STMenEdt (TPDVP002)
		U_UKeyCtr(.F., .T.)

		If lClsSys
			STWCloseDevice()
			MS_QUIT()
		EndIf
	// Felipe Sousa - 23/02/2024
	// Ajuste para melhorar performance do PDV.
	ElseIf !lOpenCash // Valida se o caixa est� fechado, se sim fecha a tela do PDV.
		//limpo a��o teclas atalho, setada no PE STMenEdt (TPDVP002)
		U_UKeyCtr(.F., .T.)

		If lClsSys
			STWCloseDevice()
			MS_QUIT()
		EndIf
	EndIf

Return lRet
