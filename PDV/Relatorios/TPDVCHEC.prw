#include 'protheus.ch'
#include 'parmtype.ch'
#include "TbiConn.ch"
#include "TopConn.ch"

//------------------------------------------------------------------------
//-- TESTE DE IMPRESSAO DE CHEQUE TROCO NA IMPRESSORA: MENNO CHECKPRINTER 
// ImpCheq -> FINR480 (IMPRESSORA MATRICIAL)
// AutoCheck6 -> FINR460 (IMPRESSORA MATRICIAL)
//------------------------------------------------------------------------
User Function TPDVCHEC(cBanco, cValor, cFavorec, cCidade, cData)

Local cPorta := AllTrim(GetPvProfString("CHECKPRINTER", "PORT", "", GetClientDir() + "SMARTCLIENT.INI"))
Local lRet := .T.
Local nRet := -1

Default cBanco := "999"
Default cValor := "0,01"
Default cFavorec := "" //"TBC - TOTVS GOIAS"
Default cCidade := "GOIANIA"
Default cData := DtoC(Date())

PRIVATE nHdll

//��������������������������������������������������������������Ŀ
//� Inicializa Handle da biblioteca para impress�o serial        �
//����������������������������������������������������������������
nHdll := 0

	//cBanco := "033" //TODO temporario 
	//U_XHELP("TPDVCHEC","cBanco: "+U_XtoStrin(cBanco)+CRLF+;
	//					"cValor: "+U_XtoStrin(cValor)+CRLF+;
	//					"cFavorec: "+U_XtoStrin(cFavorec)+CRLF+;
	//					"cCidade: "+U_XtoStrin(cCidade)+CRLF+;
	//					"cData: "+U_XtoStrin(cData)+CRLF,)

	//TODO - Abre porta serial duas vezes (nos testes so envia o comando apos a segunda abertura)
	lRet := MsOpenPort(@nHdll, cPorta+":9600,n,8,1") //sintaxe PORTA:VELOC,PARIDADE,TAM,BIT

	If !lRet .or. nHdll<=0
		//Quit
		Alert("Falha na abertura da porta serial. Porta: "+cPorta)
		Return nRet
	EndIf
	
	MsClosePort(nHdll)
	
	sleep(500) //-- aguarda meio segundo
	
	lRet := MsOpenPort(@nHdll, cPorta+":9600,n,8,1")

	If !lRet .or. nHdll<=0
		//Quit
		Alert("Falha na abertura da porta serial. Porta: "+cPorta)
		Return nRet
	EndIf
	
	sleep(500) //-- aguarda meio segundo

	//MsWrite(nHdll, chr(27) + chr(64) + chr(13) + chr(27) + chr(162) + "999" + chr(13) + ;
	//chr(27) + chr(163) + "50,00" + chr(13) + chr(27) + chr(164) + "25/04/2019 EM " /*17:15HS EM PIRACANJUBA"*/ + chr(13) + ;
	//chr(27) + chr(161) + "GOIANIA"	/*, BRASILIA, SAO PAULO, RIO, MINAS GERAIS, BELE, PARA"*/ + chr(13) + ;
	//chr(27) + chr(160) + "FAVORECIDO COAPIL 1234" /*123456789012345678901234567890" DE PIRACANJUBA"*/ + ;
	//chr(13) + chr(27) + chr(176) + chr(13) )
	
	//lRet := MsWrite(nHdll, chr(27) + chr(63)) //Verificar presen�a de cheque: retorna 0 quando o cheque n�o esta inserido e 1 para cheque inserido
	//
	//If lRet .or. nHdll<=0
	//	Alert("Cheque n�o esta inserido.")
	//	Return nRet
	//EndIf
	
	MsWrite(nHdll, ;
	chr(27) + chr(64)  +; 						//Inicializa impressora: Zera todas as vari�veis de impress�o de cheques.
	chr(27) + chr(160) + cFavorec + chr(13) + ; //Impress�o do favorecido: Este comando � utilizado para enviar o nome do favorecido para impress�o no cheque.
	chr(27) + chr(161) + cCidade  + chr(13) + ; //Impress�o do local: Utilizado para envio da localidade para impress�o do cheque.
	chr(27) + chr(162) + cBanco   + chr(13) + ; //Banco: Este comando seleciona o c�digo do banco a ser impresso o cheque.
	chr(27) + chr(163) + cValor   + chr(13) + ;	//Valor: Utilizado para enviar o valor a ser impresso no cheque.
	chr(27) + chr(164) + cData    + chr(13) + ;	//Data:: Comando para o envio da data de preenchimento do cheque.
	chr(27) + chr(176) )						//Imprime o cheque: Imprime o cheque com os dados enviados atrav�s dos comandos.
	
	MsClosePort(nHdll)
	nHdll := 0
	nRet := 0
	
Return nRet 
