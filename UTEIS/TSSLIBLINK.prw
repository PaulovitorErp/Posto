#include "totvs.ch"
#include "tbiconn.ch"

#define PREFIX "@!!@" // Nao Comer Licenca do Top

// ######################################################################################
// Projeto: CRBV
// Modulo : Ferramentas
// Fonte  : TSSLib - Rotinas de uso gen�rico
// ---------+-------------------+--------------------------------------------------------

// --------------------------------------------------------------------------------------
// N�o acesse estas variaveis diretamente/utilize sempre as fun��es de acesso
// --------------------------------------------------------------------------------------
static __TSSTopCon := -1 // identificador da conex�o do banco TSS
static __PROTopCon := AdvConnection() //identificador da conex�o atual Protheus

/*
--------------------------------------------------------------------------------------
Funcao responsavel por abrir uma nova conexao com o banco do TSS
--------------------------------------------------------------------------------------
*/  
User Function TSSOpenDB()

	//Banco TSS
	Local cTSSCon := SuperGetMV("ES_DBTSS", .F., "postgres/sigatss") //DBMS/Base de Dados do TSS
	Local cTSSSer := SuperGetMV("ES_IPTSS", .F., GetServerIP()) //Ip Servidor TSS
	Local nTSSPor := SuperGetMV("ES_PORTTSS", .F., 7890) //Porta da base de dados do TSS

	If ValType(__PROTopCon) == "U"
		__PROTopCon := AdvConnection() // obtem o ID da conexao atual
	EndIf

	If ValType(__TSSTopCon) != "U" .and. __TSSTopCon < 0

		If Empty(nTSSPor)
			__TSSTopCon := TCLINK(PREFIX+cTSSCon, cTSSSer)
		Else
			__TSSTopCon := TCLINK(PREFIX+cTSSCon, cTSSSer, nTSSPor)
		EndIf

		If __TSSTopCon < 0
			conout("Falha na conex�o TopConnect: " + cTSSSer + ":" + cValToChar(nTSSPor) +" - "+ cTSSCon + ". C�digo de erro:" + str(__TSSTopCon))
			TCQUIT()
			Return .F.
		EndIf

	EndIf

Return __TSSTopCon >= 0

/*
--------------------------------------------------------------------------------------
Fecha a conex�o ao banco de dados TSS
Ret: lRet -> l�gico, indica se a inicializa��o foi bem suscedida
--------------------------------------------------------------------------------------
*/       
User Function TSSCloseDB()
	If __TSSTopCon > -1
		TCUNLINK(__TSSTopCon)
		__TSSTopCon := -1
	EndIf
Return .T.

/*
--------------------------------------------------------------------------------------
Verifica se abriu uma conex�o ao banco de dados: TSS
--------------------------------------------------------------------------------------
*/       
User Function isTSSOpenDB()
Return __TSSTopCon >= 0

/*
--------------------------------------------------------------------------------------
Verifica se abriu uma conex�o ao banco de dados: DELIVERY
--------------------------------------------------------------------------------------
*/       
User Function isDLVOpenDB()
Return __DLVTopCon >= 0

/*
--------------------------------------------------------------------------------------
Seta conexao para TSS
--------------------------------------------------------------------------------------
*/ 
User Function TSStcSetConn()
	Local lRet := .F.
	If !U_isTSSOpenDB()
		If U_TSSOpenDB()
			lRet := tcSetConn( __TSSTopCon )
		EndIf
	Else
		lRet := tcSetConn( __TSSTopCon )
	EndIf
Return lRet

/*
--------------------------------------------------------------------------------------
Volta para conexao do Protheus
--------------------------------------------------------------------------------------
*/ 
User Function PROtcSetConn()
Return tcSetConn( __PROTopCon )

