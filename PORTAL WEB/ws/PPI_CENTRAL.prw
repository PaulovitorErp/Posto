#INCLUDE "PROTHEUS.CH"
#INCLUDE "APWEBSRV.CH"
#INCLUDE "TOPCONN.CH"
#INCLUDE "apwebex.ch"
#include "TOTVS.CH"
#INCLUDE "TBICONN.CH"
#INCLUDE "XMLXFUN.CH"

/*/{Protheus.doc} PPI_WSPOSTO

Portal Posto Inteligente
Web Service para integração com central 
Definição dos Metodos e Objetos

@author TOTVS
@since 17/02/2017
@version P12
@param Nao recebe parametros
@return nulo
/*/

WSSERVICE PPI_WSPOSTO DESCRIPTION " Funções para comunicação Portal Posto Inteligente"

	WSDATA Env_AbsPend				as WSEnvAbsPend
	WSDATA Ret_AbsPend				as WSRetAbsPend

	WSMETHOD GETABASTPEND		DESCRIPTION "Metodo para consultar abastecimentos pendentes"

ENDWSSERVICE

//----------------------------------------------------------------------------
// GETABASTPEND
//----------------------------------------------------------------------------
WSMETHOD GETABASTPEND WSRECEIVE Env_AbsPend WSSEND Ret_AbsPend WSSERVICE PPI_WSPOSTO
	
	if VldEmpFil(@::Env_AbsPend, @::Ret_AbsPend)

		U_PPIWAbPen(@::Env_AbsPend, @::Ret_AbsPend)

	endif

Return(.T.)

WSSTRUCT WSEnvAbsPend
	WSDATA 	cEmp			as String
	WSDATA 	cFil			as String
	WSDATA 	cBico			as String
	WSDATA 	cVendedor		as String
ENDWSSTRUCT

WSSTRUCT WSRetAbsPend
	WSDATA 	lRet			as Boolean
	WSDATA 	cMensagem		as String
	WSDATA 	aAbastPen		as Array of AbastPen Optional
ENDWSSTRUCT

WSSTRUCT AbastPen
	WSDATA 	cDestaca		as String
	WSDATA 	cBico			as String
	WSDATA 	cData			as String
	WSDATA 	cHora			as String
	WSDATA 	cProduto		as String
	WSDATA 	nQtd			as Float
	WSDATA 	nVlrUnit		as Float
	WSDATA 	nVlrTot			as Float
	WSDATA 	nEncerr			as Float
	WSDATA 	cVendedor		as String
ENDWSSTRUCT

//-------------------------------------------------------------------
// Valida preenchimento da filial e conecta nela
//-------------------------------------------------------------------
Static Function VldEmpFil(oEnv, oRet)

	Local lOk := .T.

	if empty(oEnv:cEmp)
		lOk := .F.
		cMsgErr := "Informe uma empresa para processamento."
	endif
	if empty(oEnv:cFil)
		lOk := .F.
		cMsgErr := "Informe uma filial para processamento."
	endif

	if lOk
		//abro ambiente na empresa esolhida no login
		If Select("SX2") == 0
			//Conout("PPI_WSPOSTO: Irá Conectar na empresa/filial: " + oEnv:cEmp+"/"+oEnv:cFil)
			//conecto na empresa/filial que foi passada pelo XML
			RpcClearEnv()
			RPCSetType(3)  // Nao comer licensa
			if !RpcSetEnv(oEnv:cEmp, oEnv:cFil, , ,'FRT',)
				cMsgErr := "Não foi possível conectar na Empresa/Filial informadas!"
				lOk := .F.
			endif
		else
			//Conout("PPI_WSPOSTO: Ja conectado na empresa/filial: " + cEmpAnt+"/"+cFilAnt)
		endif
	endif

	if !lOk
		oRet:lRet := .F.
		oRet:cMensagem := cMsgErr
	else
		oRet:cMensagem := "Busca realizada com sucesso!"
	endif

Return lOk
